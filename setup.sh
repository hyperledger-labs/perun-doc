#!/bin/bash

check_install_module() {
    module="$1"
    pkg="$2"
    python3 -c "import $module" 2>&1
    if [ $? -eq 0 ]; then
        echo "$module already installed."
        return
    fi
    echo "Installing $pkg"
    sudo apt-get install $pkg
    if [ $? -ne 0 ]; then
        echo "Installing $pkg failed.\nAbort."
        exit 1
    fi
}
check_install_python3(){
    if [ $(which python3) ]; then
        python3_ver=$(python3 --version)
        echo "$python3_ver already installed."
        return
    fi
    echo "python3 not found. Installing python3..."
    sudo apt-get install python3
    if [ $? -ne 0 ]; then
        echo "Installing python3 failed."
        exit 1
    fi
}

check_install_python3

check_install_module "pip" "python3-pip" 

#On debian based systems, --user flag is used by default when not running in virtualenv or as root
python3 -m pip install -r requirements.txt

#install other project dependencies
./deps.sh

