#!/bin/bash
# SOURCE: https://repost.aws/articles/ARGF6bVA19QC6IVcaUy-69Ag/how-do-i-install-gui-graphical-desktop-on-amazon-ec2-instances-running-suse-linux-enterprise-server-15-sles-15

# Install desktop environment and desktop manager
sudo zypper install -y -t pattern gnome_basic
sudo update-alternatives --set default-displaymanager /usr/lib/X11/displaymanagers/gdm
sudo sed -i "s/DEFAULT_WM=\"\"/DEFAULT_WM=\"gnome\"/" /etc/sysconfig/windowmanager
sudo systemctl set-default graphical.target

# Install DCV server
cd /tmp
sudo rpm --import https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
curl -L -O https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-sles15-x86_64.tgz
tar -xzf nice-dcv-sles15-x86_64.tgz && cd nice-dcv-*-sles15-x86_64
sudo zypper install -y ./nice-dcv-server-*.rpm
sudo zypper install -y ./nice-dcv-web-viewer-*.rpm
sudo zypper install -y ./nice-xdcv-*.rpm
sudo usermod -a -G video dcv
sudo systemctl enable dcvserver

# Console session XDummy driver
sudo zypper install -y xf86-video-dummy
sudo tee /etc/X11/xorg.conf > /dev/null << EOF
Section "Device"
    Identifier "DummyDevice"
    Driver "dummy"
    Option "UseEDID" "false"
    VideoRam 512000
EndSection

Section "Monitor"
    Identifier "DummyMonitor"
    HorizSync   5.0 - 1000.0
    VertRefresh 5.0 - 200.0
    Option "ReducedBlanking"
EndSection

Section "Screen"
    Identifier "DummyScreen"
    Device "DummyDevice"
    Monitor "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Viewport 0 0
        Depth 24
        Virtual 4096 2160
    EndSubSection
EndSection
EOF

# Configure DCV server
sudo sed -i "/^\[session-management\/automatic-console-session/a owner=\"support\"\nstorage-root=\"%home%\"" /etc/dcv/dcv.conf
sudo sed -i "s/^#create-session/create-session/g" /etc/dcv/dcv.conf

# Disable firewall
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Restart X server and DCV server
sudo systemctl isolate multi-user.target && sudo systemctl isolate graphical.target
sudo systemctl stop dcvserver && sudo systemctl start dcvserver

# Access graphical desktop environment
printf "You can connect to DCV server using web browser client at https://<EC2-IP>:8443 (where <EC2-IP> is your EC2 instance IP address). Native clients support additional features and can be downloaded from Amazon DCV site. Do ensure that EC2 instance security group allow inbound TCP and UDP 8443 from your IP\n\n"