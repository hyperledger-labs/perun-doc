#!/bin/bash

quiet_mode=false

# Parse command line options
while [ ! $# -eq 0 ]
do
    case "$1" in
        --help | -h)
            echo "use --quiet-mode or -q flag to run the script in non-interactive, less verbose mode"
            exit 0
            ;;
        --quiet-mode | -q)
            quiet_mode=true
            echo -e "Running setup in quiet mode : non-interactive and less verbose output\n"
            ;;
        *)
            echo "Unknown option provided: $1"
            exit 1
            ;;
    esac
    shift
done

pkg_manager_cmd="apt-get install"

# if not invoked as root, prefix sudo to package manager command
if [ ! $(whoami) == root ]; then
    pkg_manager_cmd="sudo $pkg_manager_cmd"
fi

# add -qy flags in quiet mode, to provide less verbose output and assume yes for all prompts
if [ $quiet_mode == true ]; then
    pkg_manager_cmd="$pkg_manager_cmd -qy"
fi

check_install_pkg() {

    cmd="$1"
    pkg_version_check_cmd="$2"
    pkg_to_install="$3"

    if $pkg_version_check_cmd 2>/dev/null; then
        echo -e "$($pkg_version_check_cmd) already installed.\n"
        return
    fi

    echo "$cmd not found. Installing $pkg_to_install."
    $pkg_manager_cmd $pkg_to_install

    if [ $? -ne 0 ]; then
        echo "Installing $pkg_to_install failed. Abort."
        exit 1
    fi
}

check_install_python_pkg(){

    pip_cmd="python3 -m pip install -r requirements.txt"

    #-q to suppress verbose output and print only error
    if [ $quiet_mode == true ]; then
        pip_cmd="$pip_cmd -q"
    fi

    echo -n "Installing python dependencies :........"
    if $pip_cmd; then
        echo -n -e "Successful\n\n"
    else
        exit 1
    fi
}

check_sphinx_callable(){
    if ! sphinx-build --v 2>&1 >/dev/null; then
        if [ -x ~/.local/bin/sphinx-build ]; then
            echo -e "Sphinx tools are installed in ~/.local/bin.\nThis directory is not found in system path, add it to the "'$PATH'" variable"
            exit 1
        else
            echo "'sphinx-build' not callable. Either installation failed or there is a problem with your "'$PATH'"."
            exit 1
        fi
    fi
}

check_install_plantuml() {
    mkdir -p tools
    cd tools

    plantuml_url="https://repo1.maven.org/maven2/net/sourceforge/plantuml/plantuml/1.2019.10/plantuml-1.2019.10.jar"
    plantumlPath="$PWD"

    if ! wget --no-check-certificate --no-clobber --timeout=100 $plantuml_url; then
        echo "Check internet connection"
        exit 1
    fi

    #create a wrapper to call plantuml
    touch plantuml
    echo "#!/bin/sh -e" >> plantuml
    echo "java -Djava.awt.headless=true -jar $plantumlPath/plantuml-1.2019.10.jar -failfast2 \"\$@\"" >> plantuml
    chmod +x plantuml

    echo "Plantuml available at: \"$plantumlPath\"\n"
}

# Install sphinx and required dependencies
check_install_pkg "Python" "python3 --version" "python3"
check_install_pkg "Pip" "python3 -m pip -V" "python3-pip"
check_install_python_pkg
check_sphinx_callable

# Install plantuml and required dependencies
check_install_pkg "Java" "java -version" "default-jre-headless"
check_install_pkg "Graphviz" "dot -V" "graphviz"
check_install_plantuml

echo "All dependecies successfully installed."
