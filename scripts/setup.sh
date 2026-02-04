#!/bin/bash

USERPATH=/home
read -e -p "User Path [/home]: " -i "/home" USERPATH
PRODPATH=/home
read -e -p "Product Path [/home]: " -i "/home" PRODPATH

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
read -p "Do you want to create a new user? [y/N]: " yn
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
if [[ -z "${upasswd:-}" ]]; then
  read -p "Change $user and root password? [y/N]: " yn
  case ${yn,,} in
    y|yes)
      sudo passwd root
      sudo passwd $user
      ;;
  esac
fi
if [ -d "$USERPATH/$user" ]; then
    FILEPATH="$USERPATH/$user"
else
    FILEPATH="$USERPATH"
fi
sudo mkdir -p "$PRODPATH"

# Modify OS Config
sudo timedatectl set-timezone Europe/London
sudo sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost support/" /etc/hosts
echo 'if [[ -t 0 && $- = *i* ]]; then stty -ixon; fi' \
  | tee -a /home/$user/.bashrc > /dev/null
echo 'export PS1="$PS1\[\e]1337;CurrentDir='\''\$(pwd)'\''\a\]"' \
  | tee -a /home/$user/.bash_profile > /dev/null
if [[ -f /etc/ssh/sshd_config ]]; then
  sudo sed -i -E 's/#?AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config
  sudo sed -i -E 's/#?PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sudo sed -i -E 's/#?X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
fi
if [[ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]]; then
  sudo sed -i -E 's/#?AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
  sudo sed -i -E 's/#?PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
  sudo sed -i -E 's/#?X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
fi
echo $user' ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo > /dev/null
if systemctl status sshd >/dev/null 2>&1; then
    sudo systemctl restart sshd
elif systemctl status ssh >/dev/null 2>&1; then
    sudo systemctl restart ssh
fi
sudo mkdir -p /etc/profile.d
sudo tee /etc/profile.d/profile.sh > /dev/null <<EOF
#!/bin/bash
export PATH=$PATH:$FILEPATH/AcuSupport/AcuScripts:$FILEPATH/MFSupport/MFScripts:$FILEPATH/MFSupport/MFScripts/CTFdump:$FILEPATH
export TERM=xterm
EOF
sudo chmod 775 /etc/profile.d/profile.sh
sudo grep -qxF 'fs.file-max=500000' /etc/sysctl.conf || sudo sh -c 'echo "fs.file-max=500000" >> /etc/sysctl.conf'

# Install Software
# RHEL
if [[ "$WHICHOS" = "RHEL" ]]; then
  . /etc/os-release
  sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID%.*}.noarch.rpm
  curl -s https://packages.microsoft.com/config/rhel/${VERSION_ID%.*}/prod.repo | sudo tee /etc/yum.repos.d/mssql-release.repo
  sudo tee /etc/profile.d/mssql.sh > /dev/null <<EOF
#!/bin/bash
export PATH="$PATH:/opt/mssql-tools/bin"
EOF
  sudo chmod 775 /etc/profile.d/mssql.sh
  sudo dnf update -y
  sudo dnf group install -y "Development Tools"
  sudo ACCEPT_EULA=Y yum install -y msodbcsql17 mssql-tools
  sudo dnf install -y --skip-broken unixODBC-devel wget curl cronie dos2unix htop libstdc++-devel.i686 libaio-devel glibc-devel glibc-devel.i686 glibc glibc.i686 tcpdump ed tmux openconnect jq python3 python3-pip expect postgresql postgresql-odbc net-tools lsof xterm xauth pam
  if [[ ${VERSION_ID%.*} -le 8 ]]; then
    sudo dnf install -y --skip-broken spax
  elif [[ ${VERSION_ID%.*} -ge 8 ]]; then
    sudo dnf remove -y java*
    sudo dnf install -y --skip-broken java-latest-openjdk libnsl libnsl.i686 libxcrypt libncurses* libxcrypt.i686 libgcc.i686 ncurses-libs.i686 zlib.i686 webkit2gtk3 PackageKit-gtk3-module systemd-libs systemd-libs.i686 podman buildah
  elif [[ ${VERSION_ID%.*} -ge 9 ]]; then
    sudo dnf install -y --skip-broken libxcrypt-compat libxcrypt-compat.i686
  fi
  sudo setenforce 0
  sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
  export ODBCPATH=/etc
# Ubuntu
elif [[ "$WHICHOS" = "UBUNTU" ]]; then
  . /etc/os-release
  curl -s https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
  curl -s https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
  sudo apt update
  sudo apt upgrade -y
  sudo dpkg --add-architecture amd64
  sudo dpkg --add-architecture i386
  sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18
  sudo tee /etc/profile.d/mssql.sh > /dev/null <<EOF
#!/bin/bash
export PATH="$PATH:/opt/mssql-tools18/bin"
EOF
  sudo chmod 775 /etc/profile.d/mssql.sh
  sudo apt install -y -m build-essential openjdk-21-jdk unixodbc-dev wget curl cron dos2unix htop lib32stdc++6 libstdc++6:i386 libaio-dev libncurses* apt-file zlib1g:i386 libc6:i386 libgc1 tcpdump ed tmux openconnect jq python3 python3-pip expect postgresql-client odbc-postgresql net-tools lsof pax-utils podman buildah unzip libgtk-3-0 libpam0g libpam0g:i386
  sudo apt-file update
  export ODBCPATH=/etc
# SLES
elif [[ "$WHICHOS" = "SLES" ]]; then
  sudo zypper refresh
  sudo zypper update -y
  sudo zypper install -t pattern devel_basis
  cd /tmp
  curl -s -O https://packages.microsoft.com/keys/microsoft.asc
  sudo rpm --import microsoft.asc >/dev/null
  sudo zypper ar https://packages.microsoft.com/config/sles/15/prod.repo
  sudo ACCEPT_EULA=Y zypper install -y msodbcsql17 mssql-tools
  sudo tee /etc/profile.d/mssql.sh > /dev/null <<EOF
#!/bin/bash
export PATH="$PATH:/opt/mssql-tools/bin"
EOF
  sudo chmod 775 /etc/profile.d/mssql.sh
  sudo zypper install -y unixODBC-devel wget curl cronie dos2unix htop tcpdump ed tmux jq python3 python3-pip expect postgresql net-tools lsof spax java-17-openjdk libaio-devel libaio-devel-32bit glibc-devel glibc-devel-32bit glibc glibc-32bit libcrypt1-32bit libncurses5-32bit libstdc++6-32bit libgcc_s1-32bit libz1-32bit podman buildah openconnect unzip xauth libgtk-3-0 gtk3-tools libjasper4 libnotify-tools net-tools-deprecated pam pam-32bit
  export ODBCPATH=/etc/unixODBC
fi
sudo systemctl enable --now podman.socket
sudo curl -s -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sydo chmod +x /usr/local/bin/yq
curl -LO -s "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo rm -f kubectl
sudo ln -s /usr/lib64/libnsl.so.1 /usr/lib64/libnsl.so 

# Install Oracle Instant Client
if [[ "$WHICHOS" = "RHEL" ]]; then
  if [[ ${VERSION_ID%.*} = 8 ]]; then
    oracleBaseURL=https://download.oracle.com/otn_software/linux/instantclient/2326000
    oracleBase=oracle-instantclient-basic-23.26.0.0.0-1.el8.x86_64.rpm
    oracleODBC=oracle-instantclient-odbc-23.26.0.0.0-1.el8.x86_64.rpm
    oracleSQLPlus=oracle-instantclient-sqlplus-23.26.0.0.0-1.el8.x86_64.rpm
    oracleSDK=oracle-instantclient-devel-23.26.0.0.0-1.el8.x86_64.rpm
    oraclePrecompURL=https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/23
    oraclePrecomp=oracle-instantclient-precomp-23.26.0.0.0-1.el8.x86_64.rpm
    sudo dnf install -y $oracleBaseURL/$oracleBase
    sudo dnf install -y $oracleBaseURL/$oracleODBC
    sudo dnf install -y $oracleBaseURL/$oracleSQLPlus
    sudo dnf install -y $oracleBaseURL/$oracleSDK
    curl -s -o /tmp/$oraclePrecomp $oraclePrecompURL/$oraclePrecomp
    sudo dnf install -y /tmp/$oraclePrecomp    
  elif [[ ${VERSION_ID%.*} = 9 ]]; then
    oracleBaseURL=https://download.oracle.com/otn_software/linux/instantclient/2326000
    oracleBase=oracle-instantclient-basic-23.26.0.0.0-1.el9.x86_64.rpm
    oracleODBC=oracle-instantclient-odbc-23.26.0.0.0-1.el9.x86_64.rpm
    oracleSQLPlus=oracle-instantclient-sqlplus-23.26.0.0.0-1.el9.x86_64.rpm
    oracleSDK=oracle-instantclient-devel-23.26.0.0.0-1.el9.x86_64.rpm
    oraclePrecompURL=https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/23
    oraclePrecomp=oracle-instantclient-precomp-23.26.0.0.0-1.el9.x86_64.rpm
    sudo dnf install -y $oracleBaseURL/$oracleBase
    sudo dnf install -y $oracleBaseURL/$oracleODBC
    sudo dnf install -y $oracleBaseURL/$oracleSQLPlus
    sudo dnf install -y $oracleBaseURL/$oracleSDK
    curl -s -o /tmp/$oraclePrecomp $oraclePrecompURL/$oraclePrecomp
    sudo dnf install -y /tmp/$oraclePrecomp
  fi
elif [[ "$WHICHOS" = "UBUNTU" || "$WHICHOS" == "SLES" ]]; then
  sudo mkdir -p -m 755 /opt/oracle
  cd /opt/oracle
  oraURL=https://download.oracle.com/otn_software/linux/instantclient/2326000
  oracleBase=instantclient-basic-linux.x64-23.26.0.0.0.zip
  oracleODBC=instantclient-odbc-linux.x64-23.26.0.0.0.zip
  oracleSQLPlus=instantclient-sqlplus-linux.x64-23.26.0.0.0.zip
  oracleSDK=instantclient-sdk-linux.x64-23.26.0.0.0.zip
  oraclePrecompURL=https://mturner.s3.eu-west-2.amazonaws.com/Public/Oracle/InstantClient/23
  oraclePrecomp=instantclient-precomp-linux.x64-23.26.0.0.0.zip
  baseDir=instantclient_23_0
  curl -s -O $oraURL/$oracleBase
  unzip $oracleBase
  curl -s -O $oraURL/$oracleODBC
  unzip $oracleODBC
  curl -s -O $oraURL/$oracleSQLPlus
  unzip $oracleSQLPlus
  curl -s -O $oraURL/$oracleSDK
  unzip $oracleSDK
  curl -s -o $oraclePrecomp $oraclePrecompURL/$oraclePrecomp
  unzip $oraclePrecomp
  sudo chmod -R 755 /opt/oracle
  sudo tee /etc/profile.d/oracle.sh > /dev/null <<EOF
#!/bin/bash
export PATH="$PATH:/opt/oracle/$baseDir:/opt/oracle/$baseDir/sdk"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/oracle/$baseDir"
EOF
fi

# DB2 Client
sudo mkdir -p -m 755 /opt/ibm
cd /opt/ibm
sudo curl -s -o v11.5.9_linuxx64_client.tar.gz https://mturner.s3.eu-west-2.amazonaws.com/Public/DB2/v11.5.9_linuxx64_client.tar.gz
sudo tar -zxf v11.5.9_linuxx64_client.tar.gz
sudo tee /opt/ibm/db2.linux.rsp > /dev/null <<EOF 
INTERACTIVE = NONE
LIC_AGREEMENT = ACCEPT
PROD = CLIENT
FILE = /home/$user/sqllib
COMP = BASE_CLIENT
INSTALL_TYPE = CUSTOM
EOF
/opt/ibm/client/db2setup -f sysreq -r /opt/ibm/db2.linux.rsp
sudo tee /etc/profile.d/db2.sh > /dev/null <<EOF
#!/bin/bash
. /home/$user/sqllib/db2profile
export PATH=$PATH:/home/$user/sqllib/lib64:/home/$user/sqllib/lib64/gskit:/home/$user/sqllib/lib32
EOF

# MQ Client
sudo mkdir -p -m 775 /opt/ibm/mqm
sudo curl -s -o /opt/ibm/mqm/IBM-MQC-Redist-LinuxX64.tar.gz https://mturner.s3.eu-west-2.amazonaws.com/Public/MQ/9.3.5.0-IBM-MQC-Redist-LinuxX64.tar.gz
cd /opt/ibm/mqm
sudo tar -zxf /opt/ibm/mqm/IBM-MQC-Redist-LinuxX64.tar.gz
sudo chmod 775 -R /opt/ibm/mqm
sudo tee /etc/profile.d/mq.sh > /dev/null <<EOF
#!/bin/bash
export PATH=$PATH:/opt/ibm/mqm/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/ibm/mqm/lib64
EOF

# ODBC
## odbcinst.ini
if [[ "$WHICHOS" = "RHEL" || "$WHICHOS" == "SLES" ]]; then
sudo tee -a $ODBCPATH/odbcinst.ini > /dev/null <<EOF
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

sudo tee -a $ODBCPATH/odbcinst.ini > /dev/null <<EOF
[IBM DB2 ODBC DRIVER]
Description = DB2 Driver
Driver = /home/$user/sqllib/lib64/libdb2o.so
fileusage=1
dontdlclose=1

EOF

## odbc.ini
if [[ "$WHICHOS" = "RHEL" ]]; then
  sudo tee -a $ODBCPATH/odbc.ini > /dev/null <<EOF
[oracle]
Description     = Oracle ODBC Connection
Driver          = /usr/lib/oracle/21/client64/lib/libsqora.so.21.1
Database        = $user
Servername      = 127.0.0.1:1521/FREE
UserID          = $user

EOF
elif [[ "$WHICHOS" = "UBUNTU" || "$WHICHOS" == "SLES" ]]; then
  sudo tee -a $ODBCPATH/odbc.ini > /dev/null <<EOF
[oracle]
Description     = Oracle ODBC Connection
Driver          = /opt/oracle/instantclient_21_13/libsqora.so.21.1
Database        = $user
Servername      = 127.0.0.1:1521/FREE
UserID          = $user

EOF
fi

sudo tee -a $ODBCPATH/odbc.ini > /dev/null <<EOF
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
cd $PRODPATH
sudo mkdir -p -m 775 products
sudo chown -R "$user":"$(id -gn "$user")" products

cd $FILEPATH
sudo mkdir -p -m 775 AcuSupport
cd $FILEPATH/AcuSupport
sudo mkdir -p AcuDataFiles
sudo mkdir -p AcuLogs
sudo mkdir -p AcuResources
sudo mkdir -p AcuSamples
sudo mkdir -p AcuScripts
sudo mkdir -p CustomerPrograms
sudo mkdir -p etc
sudo mkdir -p AcuServices
cd $FILEPATH
sudo chown -R "$user":"$(id -gn "$user")" AcuSupport
cd $FILEPATH/AcuSupport/AcuScripts
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuScripts/setenvacu.sh
chmod +x setenvacu.sh
cd $FILEPATH/AcuSupport/AcuServices
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuServices/acuServices.sh
chmod +x acuServices.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuServices/acurcl.service
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuServices/acuserver.service
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuServices/acuxdbcs.service
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuServices/atw.service
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/AcuServices/boomerang.service
sudo ln -s $FILEPATH/AcuSupport/AcuServices/*.service /etc/systemd/system/
sudo systemctl daemon-reload
cd $FILEPATH/AcuSupport/etc
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/a_srvcfg
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/acurcl.cfg
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/acurcl.ini
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/boomerang.cfg
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/boomerang.ini
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/cblconfig
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/fillCombo.js
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/gateway.conf
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/gateway.toml
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXextend/master/linux/etc/TCPtuning.conf

sed -i "s|/home|$PRODPATH|g" $FILEPATH/AcuSupport/AcuScripts/setenvacu.sh
sed -i "s|/home/support|$FILEPATH|g" $FILEPATH/AcuSupport/AcuScripts/startacu.sh

cd $FILEPATH
sudo mkdir -p -m 775 MFSupport
cd $FILEPATH/MFSupport
sudo mkdir -p MFScripts
sudo mkdir -p MFSamples
sudo mkdir -p MFInstallers
sudo mkdir -p MFDataFiles
sudo mkdir -p MFServices
sudo mkdir -p CTF
cd $FILEPATH/MFSupport/CTF
sudo mkdir -p TEXT
sudo mkdir -p BIN
cd $FILEPATH
sudo chown -R "$user":"$(id -gn "$user")" MFSupport
cd $FILEPATH/MFSupport/MFScripts
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/setupmf.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/setenvmf.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/mfesdiags.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/formatdumps.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/autopac.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/disableSecurity.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/MFScripts/CTFdump.zip
chmod +x *.sh
unzip -o CTFdump.zip -d $FILEPATH/MFSupport/MFScripts/
cd $FILEPATH/MFSupport/MFServices
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFServices/mfServices.sh
chmod +x mfServices.sh
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFServices/escwa.service
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFServices/fileshare.service
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFServices/mfds.service
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFServices/hacloud.service
sudo ln -s $FILEPATH/MFSupport/MFServices/*.service /etc/systemd/system/
sudo systemctl daemon-reload
cd $FILEPATH/MFSupport/CTF
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/windows/ctf.cfg
cd $FILEPATH/MFSupport/MFSamples
mkdir -p -m 775 JCL/system JCL/catalog JCL/dataset JCL/loadlib
cd $FILEPATH/MFSupport/MFSamples/JCL
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/JCL.xml
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/docs/es/MFBSI.cfg
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/docs/es/VSE.cfg
mkdir -p -m 775 CICS/system CICS/dataset CICS/loadlib
cd $FILEPATH/MFSupport/MFSamples/CICS
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXMF/main/linux/MFScripts/CICS.xml

sed -i "s|/home|$PRODPATH|g" $FILEPATH/MFSupport/MFScripts/setenvmf.sh

cd $FILEPATH
touch /home/$user/.Xauthority
sudo chmod 600 /home/$user/.Xauthority

# CRON Jobs
CRONLINE='#0 20 * * * sh -c '\''/sbin/shutdown -h +30 && printf "Shutdown scheduled for $(date -d +30mins)\\nCancel using: sudo shutdown -c" | wall'\'''
(sudo crontab -l 2>/dev/null; echo "$CRONLINE") | sudo crontab -
(sudo crontab -l ; echo "@reboot sysctl -p $FILEPATH/AcuSupport/etc/TCPtuning.conf")| sudo crontab -

# MOTD
. /etc/os-release
sudo tee motd.temp > /dev/null <<EOF
****************************************************************************************************

    $PRETTY_NAME

    AcuCOBOL
      Set Environment:
        . setenvacu.sh (-h for usage)
          
        sudo systemctl (start|stop|restart) (acurcl|atw|acuserver|acuxdbcs|boomerang)

    MFCOBOL
      Set Environment:
        . setenvmf.sh

        sudo systemctl (start|stop|restart) (escwa|mfds|fileshare|hacloud)

      Install Options:
        -IacceptEULA -ESadminID=${user} -il=$PRODPATH/products/edXXpuXX

****************************************************************************************************
EOF
sudo mv motd.temp /etc/motd
if [[ $(grep microsoft /proc/version) ]]; then
  echo "cat /etc/motd" | sudo tee -a /etc/profile.d/profile.sh
  sudo tee /etc/wsl.conf > /dev/null <<EOF
[boot]
systemd=true
[user]
default=${user}
EOF
else
  sudo sysctl -p $FILEPATH/AcuSupport/etc/TCPtuning.conf
fi