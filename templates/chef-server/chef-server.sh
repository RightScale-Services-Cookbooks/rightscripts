#!/bin/bash

set -x
set -e

echo $HOME

if [ ! -e /usr/bin/chef-client ]; then
  curl -L https://www.opscode.com/chef/install.sh | sudo bash
fi

mkdir -p /tmp/chef-install
sudo chmod -R 0777 /tmp/chef-install
cd /tmp/chef-install

if [ -e cookbooks ]; then
  rm -fr cookbooks
  mkdir -p cookbooks
fi

if [ -e chef-package.tar.gz ]; then
  rm -fr chef-package.tar.gz
fi

curl -o chef-package.tar.gz https://s3.amazonaws.com/rs-professional-services-publishing/chef-server-install/chef-package-rl10.tar.gz
tar -xzf chef-package.tar.gz -C /tmp/chef-install/

if [ -e /tmp/chef-install/chef.json ]; then
  rm -f /tmp/chef-install/chef.json
fi

cat <<EOF>/tmp/chef-install/chef.json
{
  "chef-server-blueprint": {
    "api_fqdn": "$CHEF_SERVER_FQDN",
    "version": "$CHEF_SERVER_VERSION",
    "addons": "$CHEF_SERVER_ADDONS"
  },
  "run_list": [
    "recipe[chef-server-blueprint::default]",
    "recipe[chef-server-blueprint::addons]"
  ]
}
EOF

if [ -e /tmp/chef-install/solo.rb ]; then
  rm -fr /tmp/chef-install/solo.rb
fi

cat <<EOF> /tmp/chef-install/solo.rb
cookbook_path '/tmp/chef-install/cookbooks'
EOF

echo 'PATH="/opt/opscode/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"' > /tmp/environment
sudo cp -f /tmp/environment /etc/environment
sudo /sbin/mkhomedir_helper rightlink

sudo chef-solo -l debug -L /var/log/cheflog --json-attributes /tmp/chef-install/chef.json --config /tmp/chef-install/solo.rb
