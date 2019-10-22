#!/bin/bash

#installing java 
java -version
if [ $? -eq 0 ]; then
  echo -e "Java already installed."
else
  echo "Java not found."
  echo "You can download open-jdk using the command:"
  echo -e "sudo apt-get install openjdk-8-jdk \n"
  
  exit 1
fi

#installing graphviz
graphvizStatus="$(dpkg -s graphviz | grep Status)"
if [ $? -eq 0 ] && [ "$graphvizStatus" == "Status: install ok installed" ]; then
  echo -e "Graphviz already installed."
else
  echo "Graphviz not found"
  echo "You can install Graphviz using the command:"
  echo -e "sudo apt-get install graphviz \n"
  exit 1
fi

#install plantuml
#download plantuml from maven repo
mkdir tools
cd tools
if ! wget --no-check-certificate --no-clobber --timeout=100 https://repo1.maven.org/maven2/net/sourceforge/plantuml/plantuml/1.2019.10/plantuml-1.2019.10.jar; then
    echo "Check internet connection"
    exit 1
fi
plantumlPath="$PWD"
#create a wrapper to call plantuml
touch plantuml
echo "Plantuml available at:"$plantumlPath
echo "#!/bin/sh -e" >> plantuml
echo "java -Djava.awt.headless=true -jar $plantumlPath/plantuml-1.2019.10.jar -failfast2 \"\$@\"" >> plantuml
chmod +x plantuml
echo "All dependencies are installed successfully."
