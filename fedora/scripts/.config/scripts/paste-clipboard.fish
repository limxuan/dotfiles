#!/usr/bin/env fish

set log /tmp/paste-smart.log
echo "=== Run at (date) ===" >> $log

set types (wl-paste --list-types)
echo "Clipboard types: $types" >> $log

if contains "image/png" $types
    # Clipboard contains an image
    set tmp (mktemp /tmp/clipXXXX.png)
    wl-paste --type image/png > $tmp
    echo "Pasting image: $tmp" >> $log
    Snipaste paste --files $tmp 2>>$log
    sleep 2
    rm $tmp
else
    # Clipboard contains text (possibly multiline)
    set clip (wl-paste -n | string collect)

    # Replace newlines with <br> for HTML
    set html_clip (string replace -a \n "<br>" -- $clip)

    # Escape quotes
    set safe_html (string escape -- $html_clip)

    echo "Pasting text as HTML: $clip" >> $log
    Snipaste paste --html "$safe_html" 2>>$log
end
