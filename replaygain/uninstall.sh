#!/bin/bash

echo "Uninstalling ReplayGain plugin"

# The MPD plugin's registerConfigCallback() has no unregister counterpart, so a
# stale callback would survive an uninstall and make createMPDFile() append the
# string "undefined" to mpd.conf, which stops MPD from starting. Restarting the
# backend clears the callback list. onStop() has already removed our settings
# from mpd.conf by this point.
echo "Restarting Volumio to clear the registered mpd.conf callback"
/usr/bin/sudo /bin/systemctl restart volumio.service &

echo "Done"
echo "pluginuninstallend"
