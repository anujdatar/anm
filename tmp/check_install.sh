# pkgs="curl wget"
# if ! dpkg -s $pkgs >/dev/null 2>&1; then
# 	echo $pkgs
# fi

# pkgs="curl postgress"
# if ! dpkg -s $pkgs >/dev/null 2>&1; then
# 	echo $pkgs
# fi

# qur=$(dpkg-query -l postgress)
# echo $?

# pkg="postgress"

# PKG_OK=$(dpkg-query -W -f='${Status}\n' $pkg 2>/dev/null|grep "install ok installed")
# echo Checking for $pkg: $PKG_OK
# if [ "" == "$PKG_OK" ]; then
#   echo "No $pkg. Setting up $pkg."
# fi

# dependency check
echo Checking dependencies ...
dependency="curl wget git jq postgresql nodejs npm spyder"

uninstalled=""
for pkg in $dependency
do 
  PKG_OK=$(dpkg-query -W -f='${Status}\n' $pkg 2>/dev/null)
  printf "Checking $pkg: "
  if [ "" == "$PKG_OK" ]; then
    printf "$pkg not installed. \n"
    uninstalled="$uninstalled $pkg"
  else
    printf "Installed \n"
  fi
done

echo $uninstalled
