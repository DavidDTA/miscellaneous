newapp() {
  # Usage: newapp app url profile_email
  #
  # Creates a barebones mac which wraps a website.
  # The app will be indexed in spotlight for easy access.
  #
  # The script also opens vim to edit the script that will be
  # run when the app is launched. This can be changed to have
  # the app do something other than open a webpage as an app
  # in Chrome, or it can be left alone by typing the three
  # keys "colon", "q", and "enter".
  #
  # Arguments:
  #   app:
  #     The name of the app. The script will create a directory
  #     with this name in the current directory, and the script
  #     will be accessible in spotlight under this name.
  #   url:
  #     The url that serves as the homepage of the app.
  #   profile_email:
  #     The Chrome profile email address to use. Optional.
  
  local appdir="${1//"'"/}"                                                                       
  local appdir="${appdir:-test}.app"                                                              
  local url="${2//"'"/}"
  local url="${url:-https://example.com}"                                                         
  local profile_email="${3//"'"/}"
  local contents="$appdir/Contents"
  local macos="$contents/MacOS"
  local script="$macos/script"
  if [ -e "$appdir" ]; then
    echo "whoops: $appdir exists"                                                                 
    return
  fi
  mkdir -p "$macos"                                                                               
  echo '<plist version="1.0"><dict><key>CFBundleExecutable</key><string>script</string></dict></plist>' > "$contents/Info.plist"
  echo '#!/bin/bash' >"$script"
  echo "open -n -a 'Google Chrome' --args --profile-email='$profile_email' --app='$url'" >>"$script"
  chmod +x "$script"
  vim "$script"
  mdimport "$appdir"                                                                              
} 
