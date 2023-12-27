#	Install script for SSDNode Safing VPS'  If a Tailscale install routine is to be added to this, it must be after the Portmaster install.

## Need to config gitlab for ability to login without manual process.  Need gitlab "5 Key" in place before grabbing configs.
## Fix the IPTABLES issue for the stop of forward traffic from enp3s0 to docker containers.

# Variables:
 
# Change interface name, if needed.
 IF="ens3"

#	Patch it!
 apt update
 
 DEBIAN_FRONTEND='noninteractive' apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --with-new-pkgs upgrade
 
 DEBIAN_FRONTEND='noninteractive' apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install net-tools jq whois mlocate nmap hping3 apache2-utils gnupg2 libasound2 libatk-bridge2.0-0 libatk1.0-0 libgbm1 libgtk-3-0 libnotify4 libxcb-shape0 libxcb-xfixes0 libxshmfence1 libappindicator3-1 libappindicator1 dos2unix autossh ipset man-db cron vim sudo binutils dnsutils tcpdump apt-utils apt-transport-https iptables-persistent software-properties-common wget iptables fail2ban

rm -f /etc/ssh/ssh_host_?sa_* 
 
#	Configure user "user".  Add "user" to /etc/sudoers:
 adduser --disabled-password --gecos "" user
 echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
 chmod 700 /home/user
  if [[ ! -d /home/user/.ssh ]]; \
     then mkdir /home/user/.ssh; \
  fi

  if [[ ! -f /home/user/.ssh/authorized_keys ]]; \
     then echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9o5V/PoDar9h+U4PBKrR4p0c8XEnPxfEReuK/Yo6lb" > /home/user/.ssh/authorized_keys; \
  fi
  if [[ ! -d /home/user/.kex ]]; \
     then mkdir /home/user/.kex; \
  fi
  find /home/user -type d -exec chmod 700 {} + &&  find /home/user -type f -exec chmod go-rwx {} +
  if [[ ! -d /mnt/work ]]; \
    then mkdir /mnt/work; \
  fi
 sudo sed -i 's/\#umask\ 022/umask\ 077/g' /home/user/.profile
 chown -R user:user /home/user
 
 mkdir /etc/ntopng/
 add-apt-repository universe -y
 wget https://packages.ntop.org/apt-stable/22.04/all/apt-ntop-stable.deb 
 DEBIAN_FRONTEND='noninteractive' apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install ./apt-ntop-stable.deb -y 
 apt-get clean all 
 apt-get update 
 DEBIAN_FRONTEND='noninteractive' apt -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install pfring-dkms nprobe ntopng n2disk cento -y
 service ntopng stop
 echo "# Portmaster" > /etc/ntopng/custom_protocols.txt
 echo "tcp:17@Portmaster=1024" >> /etc/ntopng/custom_protocols.txt
 echo "" >> /etc/ntopng/custom_protocols.txt
 echo "--packet-filter=\"src host $IPV4 or src host $IPV6 and not icmp6 and not icmp and not ip multicast and not ether broadcast and not ether host ff:ff:ff:ff:ff:ff and not arp and not port 17 and not port 22 and not port 53\"" >> /etc/ntopng/ntopng.conf
 echo "-m=$IPV4/32,$IPV6/128" >> /etc/ntopng/ntopng.conf
 echo "-w=:3000" >> /etc/ntopng/ntopng.conf
 echo "--ndpi-protocols=/etc/ntopng/custom_protocols.txt" >> /etc/ntopng/ntopng.conf
 echo "-i=$IF" >> /etc/ntopng/ntopng.conf
 service ntopng start

 IPV4=$(ifconfig $IF | awk '/inet / { print $2 }' | sed '/127.0/d')
 IPV6=$(ifconfig $IF | awk '/inet6 / { print $2 }' | sed -e '/fe80/d')

 iptables -F
 iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
 iptables -A INPUT -i lo -j ACCEPT
 iptables -A INPUT -i $IF -p tcp --dport 17 -m state --state NEW -j ACCEPT
 iptables -A INPUT -i $IF -p tcp --dport 22 -m state --state NEW -j ACCEPT
 iptables -A INPUT -i $IF -p tcp --dport 80 -m state --state NEW -j ACCEPT
 iptables -A INPUT -i $IF -p udp --dport 41641 -j ACCEPT
 iptables -A INPUT -i $IF -j DROP
 iptables-save > /etc/iptables/rules.v4

 ip6tables -F
 ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
 ip6tables -A INPUT -i lo -j ACCEPT
 ip6tables -A INPUT -i $IF -p tcp --dport 17 -m state --state NEW -j ACCEPT
 ip6tables -A INPUT -i $IF -p tcp --dport 22 -m state --state NEW -j ACCEPT
 ip6tables -A INPUT -i $IF -p tcp --dport 80 -m state --state NEW -j ACCEPT
 ip6tables -A INPUT -i $IF -p udp --dport 41641 -j ACCEPT
 ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
 ip6tables -A INPUT -i $IF -j DROP
 ip6tables-save > /etc/iptables/rules.v6
 
 service iptables restart
 service ip6tables restart

 sed -i 's/blocktype = REJECT --reject-with icmp-port-unreachable/blocktype = DROP/g' /etc/fail2ban/action.d/iptables-common.conf
 sed -i 's/blocktype = REJECT --reject-with icmp6-port-unreachable/blocktype = DROP/g' /etc/fail2ban/action.d/iptables-common.conf
 systemctl enable fail2ban && systemctl start fail2ban
 
 sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/safing/spn/master/tools/install.sh)"
 
 echo -e "# m h  dom mon dow   command"\\n"0 0 * * * apt update && DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --with-new-pkgs upgrade"\\n"@reboot DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' autoremove"\\n"21 4 * * 1,4,6 /sbin/shutdown -r now" > /var/spool/cron/crontabs/root
 
 reboot
