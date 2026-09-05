# ReplayGain plugin for Volumio

Plays every track at a consistent loudness using the ReplayGain tags already
stored in your files — as written by taggers such as
[rsgain](https://github.com/complexlogic/rsgain), loudgain or foobar2000.

Volumio ships an MPD build with full ReplayGain support, but never turns it on:
the `replaygain` lines have been commented out in `mpd.conf.tmpl` since 2016,
so MPD always runs with `replay_gain_mode: off` and your tags are ignored. This
plugin switches it on without touching anything under `/volumio`.

## What it affects

Everything that plays through MPD — local and NAS libraries, web radio, and
plugins that hand MPD a stream URL, including Jellyfin. Tags are read straight
off the stream, so a Jellyfin library tagged with rsgain works without any
transcoding or re-tagging.

Sources that bypass MPD (Spotify, YouTube Cast, AirPlay) are unaffected;
ReplayGain cannot reach them.

## Settings

| Setting | Meaning |
| --- | --- |
| **ReplayGain** | `Album gain` keeps the loudness differences within an album intact — the right choice for album listening. `Track gain` levels every track on its own. `Auto` uses track gain when shuffling and album gain otherwise. `Off` disables it. |
| **ReplayGain preamp** | Gain applied on top of ReplayGain, −6 to +12 dB. ReplayGain targets a fairly quiet reference level, so a positive preamp is often desirable. |

Tracks without ReplayGain tags are left untouched (`replaygain_missing_preamp
"0"`), and clipping is prevented automatically using the peak tags
(`replaygain_limit "yes"`).

Saving restarts MPD, which interrupts playback for a moment.

## How it works

Rather than editing Volumio's files, the plugin uses the MPD plugin's
`registerConfigCallback()` extension point. Volumio regenerates `/etc/mpd.conf`
from a template on every output or playback change; on each regeneration it
asks registered plugins for extra lines and appends them. This plugin
contributes:

```
### ReplayGain (managed by the replaygain plugin)
replaygain                      "album"
replaygain_preamp               "0"
replaygain_missing_preamp       "0"
replaygain_limit                "yes"
```

Because nothing under `/volumio` is modified, the settings survive OTA updates
without pinning any Volumio file to an old version in the overlay filesystem —
which is what editing `mpd.conf.tmpl` by hand does, and what Volumio's own
[filesystem docs](https://developers.volumio.com/Architecture/filesystem-architecture)
warn against.

## Installing

The plugin depends on `kew` and `v-conf`, and Volumio does not put its own
`node_modules` on the plugin module search path, so they have to be bundled.
`volumio plugin package` does that for you:

```bash
volumio plugin package    # produces replaygain.zip with node_modules included
volumio plugin install    # or upload the zip to http://<player>:3000/plugin-upload
```

## Note on uninstalling

`registerConfigCallback()` has no unregister counterpart, and `createMPDFile()`
appends the callback's return value with no guard against `undefined`. A stale
callback left behind by an uninstall would therefore write the literal string
`undefined` into `mpd.conf` and stop MPD from starting. `uninstall.sh` restarts
the Volumio backend to clear the callback list; let it finish.

## If you already edited mpd.conf.tmpl by hand

A widely circulated forum recipe tells people to append `replaygain` lines to
`/volumio/app/plugins/music_service/mpd/mpd.conf.tmpl` over SSH. Undo that
before using this plugin. The template would then define `replaygain` itself
and the plugin would write it a second time, which MPD rejects as a redefined
setting. The plugin notices, logs an error and contributes nothing rather than
leaving you with a player that will not start — but you would be running the
hand-edit's settings instead of the plugin's, and an edited file under
`/volumio` shadows the shipped one on every future update.
