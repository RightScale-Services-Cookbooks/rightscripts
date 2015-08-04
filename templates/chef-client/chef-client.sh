#!/bin/bash

set -x
set -e

echo $HOME

if [[ ! -z $VERSION ]]; then
  version="-v $VERSION"
fi

if [ ! -e /usr/bin/chef-client ]; then
  curl -L https://www.opscode.com/chef/install.sh $version | sudo bash
fi

sudo /sbin/mkhomedir_helper rightlink
sudo mkdir -p /etc/chef

export chef_dir=$HOME/.chef
mkdir -p $chef_dir

sudo cat <<EOF> $chef_dir/validation.pem
$CHEF_VALIDATION_KEY
EOF

mkdir -p $chef_dir/trusted_certs
#get this by knife fetch ssl
cat <<EOF> $chef_dir/trusted_certs/chef-server.crt
$CHEF_SERVER_SSL_CERT
EOF


if [ -e $chef_dir/chef.json ]; then
  rm -f $chef_dir/chef.json
fi

cat <<EOF> $chef_dir/chef.json
{
  "name": "$HOSTNAME",
  "normal": {
    "company": "$CHEF_COMPANY",
    "tags": [
    ]
  },
  "chef_environment": "$CHEF_ENVIRONMENT",
  "run_list": "$CHEF_SERVER_RUNLIST"
}
EOF

if [ -e $chef_dir/client.rb ]; then
  rm -fr $chef_dir/client.rb
fi

cat <<EOF> $chef_dir/client.rb
log_level              :debug
log_location           '/var/log/chef.log'
chef_server_url        "$CHEF_SERVER_URL"
validation_client_name "$CHEF_VALIDATION_NAME"
node_name              "$HOSTNAME"
cookbook_path          "~/cookbooks/"
validation_key "$chef_dir/validation.pem"
EOF

sudo chef-client --json-attributes $chef_dir/chef.json --config $chef_dir/client.rb
