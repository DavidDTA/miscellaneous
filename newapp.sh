newapp() {                                                                                        
  local appdir="${1//"'"/}"                                                                       
  local appdir="${appdir:-test}.app"                                                              
  local url="${2//"'"/}"
  local url="${url:-https://example.com}"                                                         
  local profile="${3//"'"/}"
  local profile="${profile:-Default}"                                                             
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
  echo "open -n -a 'Google Chrome' --args --profile-directory='$profile' --app='$url'" >>"$script"
  chmod +x "$script"
  vim "$script"
  mdimport "$appdir"                                                                              
} 
