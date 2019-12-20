#!/bin/bash

grep_ver="grep -o [0-9.]*"
grep_perm_denied="grep -o Permission"
grep_success="grep -o Successfully"

check_install_pkg() {
    pip_tool="pip$1"
    pkg="$2"
    #Check python-$pkg version, if not available install
    pkg_ver=$($pip_tool show $pkg 2>&1| grep --line-buffered "^Version" | $grep_ver) 
    if [ -n "$pkg_ver" ]; then
        echo "$pkg version - $pkg_ver found"
    else
        echo "$pkg not found. Installing $pkg..."
        install_output=$($pip_tool install $pkg 2>&1)
        if [ -n "$(echo $install_output | $grep_perm_denied)" ]; then 
            install_output=$($pip_tool install --user $pkg 2>&1)

            if [ -n "$(echo $install_output | $grep_success)" ]; then 
            pkg_ver=$($pip_tool show $pkg | grep --line-buffered "^Version"  | $grep_ver) 
            echo "Successfully installed $pkg version $pkg_ver"
            fi
        elif [ -n "$(echo $install_output | $grep_success)" ]; then
            pkg_ver=$($pip_tool show $pkg | grep --line-buffered "^Version"  | $grep_ver) 
            echo "Successfully installed $pkg version $pkg_ver"
        else 
            echo "Unknown error installing $pkg"
            echo $install_output
        fi
    fi
}
check_install_pip2(){

	pip_ver=$($pip --version | grep --line-buffered "^Version")
	if [ -n "$pip_ver" ]; then
		echo "$pip_ver found"

	else
		echo "pip not found, Installing... "
		install_output=$(sudo apt install python-pip)
	fi

	if [ -n "$(echo $install_output | $grep_success)" ]; then
            pip_ver=$(pip --version | sed 's/from/at/g')
            echo "Successfully installed $pip_ver"
        else
            echo "Unknown error installing pip"             
        fi
}
check_install_pip3(){

	pip_ver=$($pip --version | grep --line-buffered "^Version")
	if [ -n "$pip_ver" ]; then
		echo "$pip_ver found"

	else
		echo "pip not found, Installing... "
		install_output=$(sudo apt install python3-pip)
	fi

	if [ -n "$(echo $install_output | $grep_success)" ]; then
            pip_ver=$(pip --version | sed 's/from/at/g')
            echo "Successfully installed $pip_ver"
        else
            echo "Unknown error installing pip"
        fi
}

#Check python2 version, if not available install
python2_ver=$(python --version 2>&1 | $grep_ver)
python3_ver=$(python3 --version | $grep_ver)
if [ -n "$python2_ver" ]; then
    echo "python2 version - $python2_ver found"
    check_install_pip2
    check_install_pkg "2" "sphinx"
    check_install_pkg "2" "sphinx-rtd-theme"
else
    #Check python3 version, if not available, install python2 and corresponding sphinx
    if [ -n "$python3_ver" ]; then
        echo "python3 version - $python3_ver found"
        #if python3 is installed, check_install_sphinx3
        check_install_pip3
        check_install_pkg "3" "sphinx"
        check_install_pkg "3" "sphinx-rtd-theme"
    else 
        echo "python2 not found. Installing python2..."
        sudo apt-get install python2
        check_install_pip2
        check_install_pkg "2" "sphinx"
        check_install_pkg "2" "sphinx-rtd-theme"
    fi
fi

#install other project dependencies
./deps.sh