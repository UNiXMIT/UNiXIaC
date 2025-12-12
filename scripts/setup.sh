#!/bin/bash

BASEPATH=/home

# Detect OS
if command -v dnf >/dev/null; then
  export WHICHOS=RHEL
elif command -v apt >/dev/null; then
  export WHICHOS=UBUNTU
elif command -v zypper >/dev/null; then
  export WHICHOS=SLES
else
  echo "OS not identified!"
  exit 1
fi

# Manage Users
read -p "Do you want to create a new user? [Y/N]: " yn
yn=${yn,,}
if [[ "$yn" == "y" || "$yn" == "yes" ]]; then
  read -p "User to create: " user
  read -p "${user} password to set: " upasswd
  if id "$user" >/dev/null 2>&1; then
      echo $user user found, continuing...
  else
      sudo adduser support
  fi
  echo "root:$upasswd" | sudo chpasswd
  echo "$user:$upasswd" | sudo chpasswd
else
  export user=$USER
fi

# Modify OS Config
sudo timedatectl set-timezone Europe/London
sudo hostnamectl set-hostname $user
sudo sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost ${user}/" /etc/hosts
echo "if [[ -t 0 && $- = *i* ]]; then stty -ixon; fi" >> /home/$user/.bashrc
echo 'export PS1="$PS1\[\e]1337;CurrentDir='\''\$(pwd)'\''\a\]"' >> /home/$user/.bash_profile
if [[ -f /etc/ssh/sshd_config ]]; then
  sudo sed -i -E 's/#?AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config;
  sudo sed -i -E 's/#?PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config;
  sudo sed -i -E 's/#?X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config;
fi
if [[ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]]; then
  sudo sed -i -E 's/#?AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
  sudo sed -i -E 's/#?PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf;
  sudo sed -i -E 's/#?X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config;
fi
echo $user' ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
sudo service ssh restart &>/dev/null
sudo service sshd restart &>/dev/null  
sudo mkdir -p /etc/profile.d
sudo cat > /etc/profile.d/profile.sh <<EOF
#!/bin/bash
export PATH=$PATH:/home/$user/AcuSupport/AcuScripts:/home/$user/MFSupport/MFScripts:/home/$user
export TERM=xterm
EOF
sudo chmod 775 /etc/profile.d/profile.sh
sudo grep -qxF 'fs.file-max=500000' /etc/sysctl.conf || sudo sh -c 'echo "fs.file-max=500000" >> /etc/sysctl.conf'

# Install Software
# RHEL
if [ "$WHICHOS" = "RHEL" ]; then
  . /etc/os-release;
  sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID%.*}.noarch.rpm;
  curl https://packages.microsoft.com/config/rhel/${VERSION_ID%.*}/prod.repo | sudo tee /etc/yum.repos.d/mssql-release.repo
  sudo cat > /etc/profile.d/mssql.sh <<EOF
#!/bin/bash
export PATH="$PATH:/opt/mssql-tools/bin"
EOF
  sudo chmod 775 /etc/profile.d/mssql.sh
  sudo dnf update -y;
  sudo dnf group install -y "Development Tools";
  sudo ACCEPT_EULA=Y yum install -y msodbcsql17 mssql-tools
  sudo dnf install -y --skip-broken unixODBC-devel wget curl cronie dos2unix htop libstdc++-devel.i686 libaio-devel glibc-devel glibc-devel.i686 glibc glibc.i686 tcpdump ed tmux openconnect jq python3 python3-pip expect postgresql postgresql-odbc net-tools lsof xterm xauth
  if [[ ${VERSION_ID%.*} -le 8 ]]; then
    sudo dnf install -y --skip-broken spax;
  elif [[ ${VERSION_ID%.*} -ge 8 ]]; then
    sudo dnf remove -y java*
    sudo dnf install -y --skip-broken java-latest-openjdk libnsl libnsl.i686 libxcrypt libncurses* libxcrypt.i686 libgcc.i686 ncurses-libs.i686 zlib.i686 webkit2gtk3 PackageKit-gtk3-module systemd-libs systemd-libs.i686 podman buildah
  elif [[ ${VERSION_ID%.*} -ge 9 ]]; then
    sudo dnf install -y --skip-broken libxcrypt-compat libxcrypt-compat.i686;
  fi
  sudo setenforce 0;
  sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config;
  export ODBCPATH=/etc
# Ubuntu
elif [ "$WHICHOS" = "UBUNTU" ]; then
  . /etc/os-release
  curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
  curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
  sudo apt update;
  sudo apt upgrade -y;
  sudo dpkg --add-architecture amd64;
  sudo dpkg --add-architecture i386;
  sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18
  sudo cat > /etc/profile.d/mssql.sh <<EOF
#!/bin/bash
export PATH="$PATH:/opt/mssql-tools18/bin"
EOF
  sudo chmod 775 /etc/profile.d/mssql.sh
  sudo apt install -y -m build-essential openjdk-21-jdk unixodbc-dev wget curl cron dos2unix htop lib32stdc++6 libstdc++6:i386 libaio-dev libncurses* apt-file zlib1g:i386 libc6:i386 libgc1 tcpdump ed tmux openconnect jq python3 python3-pip expect postgresql-client odbc-postgresql net-tools lsof pax-utils podman buildah unzip libgtk-3-0;
  sudo apt-file update;
  export ODBCPATH=/etc
# SLES
elif [ "$WHICHOS" = "SLES" ]; then
  sudo zypper refresh;
  sudo zypper update -y;
  sudo zypper install -t pattern devel_basis
  cd /tmp
  curl -s -O https://packages.microsoft.com/keys/microsoft.asc
  sudo rpm --import microsoft.asc
  sudo zypper ar https://packages.microsoft.com/config/sles/15/prod.repo
  sudo ACCEPT_EULA=Y zypper install -y msodbcsql17 mssql-tools
  sudo cat > /etc/profile.d/mssql.sh <<EOF
#!/bin/bash
export PATH="$PATH:/opt/mssql-tools/bin"
EOF
  sudo chmod 775 /etc/profile.d/mssql.sh
  sudo zypper install -y unixODBC-devel wget curl cronie dos2unix htop tcpdump ed tmux jq python3 python3-pip expect postgresql net-tools lsof spax java-17-openjdk libaio-devel libaio-devel-32bit glibc-devel glibc-devel-32bit glibc glibc-32bit libcrypt1-32bit libncurses5-32bit libstdc++6-32bit libgcc_s1-32bit libz1-32bit podman buildah openconnect unzip xauth libgtk-3-0 gtk3-tools libjasper4 libnotify-tools net-tools-deprecated pam pam-32bit;
  export ODBCPATH=/etc/unixODBC
fi
sudo systemctl enable --now podman.socket
sudo curl -s -o /usr/local/bin/yq_linux_amd64 https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
ln -s /usr/lib64/libnsl.so.1 /usr/lib64/libnsl.so 

# Install Oracle Instant Client
if [ "$WHICHOS" = "RHEL" ]; then
  if [[ ${VERSION_ID%.*} = 8 ]]; then
    sudo dnf install -y https://download.oracle.com/otn_software/linux/instantclient/2113000/oracle-instantclient-basic-21.13.0.0.0-1.el8.x86_64.rpm
    sudo dnf install -y https://download.oracle.com/otn_software/linux/instantclient/2113000/oracle-instantclient-odbc-21.13.0.0.0-1.el8.x86_64.rpm
    sudo dnf install -y https://download.oracle.com/otn_software/linux/instantclient/2113000/oracle-instantclient-sqlplus-21.13.0.0.0-1.el8.x86_64.rpm
    sudo dnf install -y https://download.oracle.com/otn_software/linux/instantclient/2113000/oracle-instantclient-devel-21.13.0.0.0-1.el8.x86_64.rpm
    curl -s -o /tmp/oracle-instantclient-precomp-21.13.0.0.0-1.el8.x86_64.rpm https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/21/oracle-instantclient-precomp-21.13.0.0.0-1.el8.x86_64.rpm
    sudo dnf install -y /tmp/oracle-instantclient-precomp-21.13.0.0.0-1.el8.x86_64.rpm
    
  elif [[ ${VERSION_ID%.*} = 9 ]]; then
    sudo dnf install -y https://download.oracle.com/otn_software/linux/instantclient/2112000/el9/oracle-instantclient-basic-21.12.0.0.0-1.el9.x86_64.rpm
    sudo dnf install -y https://download.oracle.com/otn_software/linux/instantclient/2112000/el9/oracle-instantclient-odbc-21.12.0.0.0-1.el9.x86_64.rpm
    sudo dnf install -y https://download.oracle.com/otn_software/linux/instantclient/2112000/el9/oracle-instantclient-sqlplus-21.12.0.0.0-1.el9.x86_64.rpm
    sudo dnf install -y https://download.oracle.com/otn_software/linux/instantclient/2112000/el9/oracle-instantclient-devel-21.12.0.0.0-1.el9.x86_64.rpm
    curl -s -o /tmp/oracle-instantclient-precomp-21.12.0.0.0-1.el9.x86_64.rpm https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/21/oracle-instantclient-precomp-21.12.0.0.0-1.el9.x86_64.rpm
    sudo dnf install -y /tmp/oracle-instantclient-precomp-21.12.0.0.0-1.el9.x86_64.rpm
  fi
elif [ "$WHICHOS" = "UBUNTU" || "$WHICHOS" == "SLES" ]; then
  sudo mkdir -m 755 /opt/oracle
  cd /opt/oracle
  curl -s -O https://download.oracle.com/otn_software/linux/instantclient/2113000/instantclient-basic-linux.x64-21.13.0.0.0dbru.zip
  unzip instantclient-basic-linux*.zip
  curl -s -O https://download.oracle.com/otn_software/linux/instantclient/2113000/instantclient-odbc-linux.x64-21.13.0.0.0dbru.zip
  unzip instantclient-odbc*.zip
  curl -s -O https://download.oracle.com/otn_software/linux/instantclient/2113000/instantclient-sqlplus-linux.x64-21.13.0.0.0dbru.zip
  unzip instantclient-sqlplus*.zip
  curl -s -O https://download.oracle.com/otn_software/linux/instantclient/2113000/instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip
  unzip instantclient-sdk*.zip
  curl -s -o instantclient-precomp-linux.x64-21.13.0.0.0dbru.zip https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/21/instantclient-precomp-linux.x64-21.13.0.0.0dbru.zip
  unzip instantclient-precomp*.zip
  sudo chmod -R 755 /opt/oracle
  sudo cat > /etc/profile.d/oracle.sh <<EOF
#!/bin/bash
export PATH="$PATH:/opt/oracle/instantclient_21_13:/opt/oracle/instantclient_21_13/sdk"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/oracle/instantclient_21_13"
EOF
fi

# DB2 Client
sudo mkdir -m 755 /opt/ibm
cd /opt/ibm
curl -o v11.5.9_linuxx64_client.tar.gz https://mturner.s3.eu-west-2.amazonaws.com/Public/DB2/v11.5.9_linuxx64_client.tar.gz
tar -zxf v11.5.9_linuxx64_client.tar.gz
sudo cat > /opt/ibm/db2.linux.rsp <<EOF 
INTERACTIVE = NONE
LIC_AGREEMENT = ACCEPT
PROD = CLIENT
FILE = /home/$user/sqllib
COMP = BASE_CLIENT
INSTALL_TYPE = CUSTOM
EOF
/opt/ibm/client/db2setup -f sysreq -r /opt/ibm/db2.linux.rsp
sudo cat > /etc/profile.d/db2.sh <<EOF
#!/bin/bash
. /home/$user/sqllib/db2profile
export PATH=$PATH:/home/$user/sqllib/lib64:/home/$user/sqllib/lib64/gskit:/home/$user/sqllib/lib32
EOF

# MQ Client
sudo mkdir -p -m 775 /opt/ibm/mqm
curl -s -o /opt/ibm/mq/IBM-MQC-Redist-LinuxX64.tar.gz -L https://mturner.s3.eu-west-2.amazonaws.com/Public/MQ/9.3.5.0-IBM-MQC-Redist-LinuxX64.tar.gz
cd /opt/ibm/mqm
tar -zxf /opt/ibm/mq/IBM-MQC-Redist-LinuxX64.tar.gz
sudo chmod 775 -R /opt/ibm/mqm
sudo cat > /etc/profile.d/mq.sh <<EOF
#!/bin/bash
export PATH=$PATH:/opt/ibm/mq/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/ibm/mq/lib64
EOF

# ODBC
## odbcinst.ini
sudo cat >> $ODBCPATH/odbcinst.ini <<EOF
[PostgreSQL ANSI]
Description=PostgreSQL ODBC driver (ANSI version)
Driver=psqlodbca.so
Setup=libodbcpsqlS.so

[PostgreSQL Unicode]
Description=PostgreSQL ODBC driver (Unicode version)
Driver=psqlodbcw.so
Setup=libodbcpsqlS.so

[IBM DB2 ODBC DRIVER]
Description = DB2 Driver
Driver = /home/$user/sqllib/lib64/libdb2o.so
fileusage=1
dontdlclose=1
EOF

if [ "$WHICHOS" = "RHEL" || "$WHICHOS" == "SLES" && "$WHICHOS" != "UBUNTU" ]; then
sudo cat >> $ODBCPATH/odbcinst.ini <<EOF
[PostgreSQL ANSI]
Description=PostgreSQL ODBC driver (ANSI version)
Driver=psqlodbca.so
Setup=libodbcpsqlS.so

[PostgreSQL Unicode]
Description=PostgreSQL ODBC driver (Unicode version)
Driver=psqlodbcw.so
Setup=libodbcpsqlS.so
EOF
fi

## odbc.ini
if [ "$WHICHOS" = "RHEL" ]; then
  sudo cat >> $ODBCPATH/odbc.ini <<EOF
[oracle]
Description     = Oracle ODBC Connection
Driver          = /usr/lib/oracle/21/client64/lib/libsqora.so.21.1
Database        = $user
Servername      = 127.0.0.1:1521/FREE
UserID          = $user
EOF
elif [ "$WHICHOS" = "UBUNTU" || "$WHICHOS" == "SLES" ]; then
  sudo cat >> $ODBCPATH/odbc.ini <<EOF
[oracle]
Description     = Oracle ODBC Connection
Driver          = /opt/oracle/instantclient_21_13/libsqora.so.21.1
Database        = $user
Servername      = 127.0.0.1:1521/FREE
UserID          = $user
EOF
fi

sudo cat >> $ODBCPATH/odbc.ini <<EOF
[mssql]  
Driver = ODBC Driver 17 for SQL Server  
Server = tcp:localhost,1433
Encrypt = yes
TrustServerCertificate = yes

[postgres]
Description     = PostgreSQL ODBC connection
Driver          = PostgreSQL ANSI
Database        = $user
Servername      = 127.0.0.1
UserName        = $user
Password        = strongPassword123
Port            = 5432

[db2]
Driver = IBM DB2 ODBC DRIVER
Database = $user
Server = localhost
Port = 50000
UID = $user
PWD = strongPassword123
EOF

# Create Support Files and Directories
cd $BASEPATH
[ ! -d "products" ] && sudo mkdir -m 775 products
if [ "$WHICHOS" = "RHEL" || "$WHICHOS" = "UBUNTU" ]; then
  sudo chown -R $user:$user products
elif [ "$WHICHOS" == "SLES" ]; then
  sudo chown -R $user:users products
fi

cd /home/$user
[ ! -d "AcuSupport" ] && mkdir -m 775 AcuSupport
cd /home/$user/AcuSupport
[ ! -d "AcuDataFiles" ] && mkdir AcuDataFiles
[ ! -d "AcuLogs" ] && mkdir AcuLogs
[ ! -d "AcuResources" ] && mkdir AcuResources
[ ! -d "AcuSamples" ] && mkdir AcuSamples
[ ! -d "AcuScripts" ] && mkdir AcuScripts
[ ! -d "CustomerPrograms" ] && mkdir CustomerPrograms
[ ! -d "etc" ] && mkdir etc
cd /home/$user/AcuSupport/AcuScripts
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuScripts/setenvacu.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuScripts/startacu.sh
sudo chmod +x setenvacu.sh startacu.sh
cd /home/$user/AcuSupport/etc
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/a_srvcfg
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/acurcl.cfg
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/acurcl.ini
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/boomerang.cfg
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/boomerang_alias.ini
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/cblconfig
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/fillCombo.js
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/gateway.conf
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/gateway.toml
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/TCPtuning.conf

cd /home/$user
[ ! -d "MFSupport" ] && mkdir -m 775 MFSupport
cd /home/$user/MFSupport
[ ! -d "MFScripts" ] && mkdir MFScripts
[ ! -d "MFSamples" ] && mkdir MFSamples
[ ! -d "MFInstallers" ] && mkdir MFInstallers
[ ! -d "MFDataFiles" ] && mkdir MFDataFiles
[ ! -d "CTF" ] && mkdir CTF
cd /home/$user/MFSupport/CTF
[ ! -d "TEXT" ] && mkdir TEXT
[ ! -d "BIN" ] && mkdir BIN

cd /home/$user/MFSupport/MFScripts
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/setupmf.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/startmf.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/setenvmf.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/mfesdiags.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/formatdumps.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/autopac.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/disableSecurity.sh
sudo chmod +x setupmf.sh startmf.sh setenvmf.sh formatdumps.sh autopac.sh mfesdiags.sh disableSecurity.sh
cd /home/$user/MFSupport/CTF
cur -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/ctf.cfg
cd /home/$user/MFSuport/MFSamples
if [ ! -d "JCL" ]; then
  mkdir -m 775 JCL
  mkdir -m 775 JCL/system JCL/catalog JCL/dataset JCL/loadlib
  curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/JCL.xml
  curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/docs/es/MFBSI.cfg
  curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/docs/es/VSE.cfg
fi
if [ ! -d "CICS" ]; then
  mkdir -m 775 CICS
  mkdir -m 775 CICS/system CICS/dataset JCL/loadlib
  curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/CICS.xml
fi
sudo chmod -R 775 /home/$user

touch /home/$user/.Xauthority
sudo chmod 600 /home/$user/.Xauthority

# CRON Jobs
CRONLINE='#0 20 * * * sh -c '\''/sbin/shutdown -h +30 && printf "Shutdown scheduled for $(date -d +30mins)\\nCancel using: sudo shutdown -c" | wall'\'''
(sudo crontab -l 2>/dev/null; echo "$CRONLINE") | sudo crontab -
(sudo crontab -l ; echo "@reboot sysctl -p /home/$user/AcuSupport/etc/TCPtuning.conf")| sudo crontab -

# MOTD
. /etc/os-release
cat > motd.temp <<EOF
****************************************************************************************************

    $PRETTY_NAME

    AcuCOBOL
      Set Environment:
        . setenvacu.sh (-h for usage)
          
        startacu.sh (-h for usage)

    MFCOBOL
      Set Environment:
        . setenvmf.sh

        startmf.sh (-h for usage)

      Install Options:
        -IacceptEULA -ESadminID=${user} -il=$BASEPATH/products/esXXpuXX

****************************************************************************************************
EOF
sudo mv motd.temp /etc/motd
if [[ $(grep microsoft /proc/version) ]]; then
  echo "cat /etc/motd" >> /etc/profile.d/profile.sh
  sudo cat > /etc/wsl.conf <<EOF
[boot]
systemd=true
[user]
default=${user}
EOF
else
  sudo sysctl -p /home/$user/AcuSupport/etc/TCPtuning.conf
fi