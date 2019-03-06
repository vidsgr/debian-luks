      apt-get update
      apt-get install -y openssl sudo openssh-server apt-transport-https dirmngr 
      #apt-get install -y libelf-devel
      #apt-get install -y libelf-dev
      #apt-get install -y elfutils-libelf-devel
      #wget -q -O - http://multipath-tcp.org/mptcp.gpg.key | apt-key add -
      yes '' |apt-key adv --keyserver hkp://keys.gnupg.net:80 --recv-keys 379CE192D401AB61
      #yes '' |apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv-keys 379CE192D401AB61
      #echo 'deb-src http://cdn.debian.net/debian stable main' >> /etc/apt/sources.list
      #echo 'deb-src http://cdn.debian.net/debian stable contrib' >> /etc/apt/sources.list
      #echo 'deb-src http://cdn.debian.net/debian stable non-free' >> /etc/apt/sources.list
      echo 'deb https://dl.bintray.com/cpaasch/deb stretch main' > /etc/apt/sources.list.d/mptcp.list
      apt-get update
      #apt-get install -y --allow-unauthenticated linux-mptcp
      apt-get install -y linux-mptcp
      #curl https://raw.githubusercontent.com/multipath-tcp/mptcp-scripts/master/scripts/rt_table/mptcp_up -o /etc/network/if-up.d/mptcp_up
      #chmod +x /etc/network/if-up.d/mptcp_up

      #curl https://raw.githubusercontent.com/multipath-tcp/mptcp-scripts/master/scripts/rt_table/mptcp_down -o /etc/network/if-post-down.d/mptcp_down
      #apt-get build-dep linux-image-$(uname -r) -y
      #chmod +x /etc/network/if-post-down.d/mptcp_down
      #cd /usr/src/
      #cd $(find ./ -name "*.mptcp" -maxdepth 1|cut -d/ -f2-)
      #make modules_prepare
