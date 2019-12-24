#!/bin/bash

grep_ver="grep -o [0-9.]*"
grep_perm_denied="grep -o Permission"
grep_success="grep -o Successfully"

check_install_pkg() {
    pip_tool="pip"
    pkg="$1"
    #Check python-$pkg version, if not available install
    pkg_ver=$($pip_tool show $pkg 2>&1| grep --line-buffered "^Version" | $grep_ver) 
    is_pkg_dep_satisfied=$($pip_tool check $pkg 2>&1 | grep "No broken requirements found")
    if [ -n "$pkg_ver" ] && [ -n "$is_pkg_dep_satisfied" ]; then
        echo "$pkg version - $pkg_ver found"
    else
        echo "$pkg not found or missing dependencies. Installing $pkg..."
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

check_install_pip3(){

	pip_ver=$(pip3 --version | grep -o "pip[ 0-9\.]*" | $grep_ver)
	if [ -n "$pip_ver" ]; then
		echo "pip $pip_ver found"

	else
		echo "pip not found, Installing... "
		install_output=$(sudo apt-get install python3-pip)

        pip_ver=$(pip3 --version | grep -o "pip[ 0-9\.]*" | grep -o "[0-9.]*")
	    if [ -n "$pip_ver" ]; then
            echo "Successfully installed pip $pip_ver"
        else
            echo "Unknown error installing pip"
        fi
    fi
}

check_install_python3(){
    python3_ver=$(python3 --version | $grep_ver)

    if [ -n "$python3_ver" ]; then
        echo "python3 version - $python3_ver found"
    else 
        echo "python3 not found. Installing python3..."
        sudo apt-get install python3
    fi
}

check_install_python3
check_install_pip3
check_install_pkg "sphinx"
check_install_pkg "sphinx-rtd-theme"

#install other project dependencies
./deps.sh