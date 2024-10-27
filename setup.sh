

## Basics

# install required tool versions
mise install

## Extensions 

# Camel JBang
jbang app install --force camel@apache/camel

# Apache Camel JBang Kubernetes plugin
camel plugin add kubernetes
echo "Camel plugins updated:"
camel plugin get   