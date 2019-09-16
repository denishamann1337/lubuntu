FROM phusion/baseimage:0.11

# reenable ssh
RUN rm -f /etc/service/sshd/down

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Running scripts during container startup
RUN mkdir -p /etc/my_init.d
COPY vncserver.sh /etc/my_init.d/vncserver.sh
RUN chmod +x /etc/my_init.d/vncserver.sh
RUN chmod 755 /etc/container_environment
RUN chmod 644 /etc/container_environment.sh /etc/container_environment.json
# Give children processes 5 minutes to timeout
ENV KILL_PROCESS_TIMEOUT=300
# Give all other processes (such as those which have been forked) 5 minutes to timeout
ENV KILL_ALL_PROCESSES_TIMEOUT=300

# Install lubuntu-desktop
COPY sources.list /etc/apt/sources.list
RUN dpkg --remove-architecture i386
RUN apt-get update
RUN apt-get install -yqq sudo wget curl htop nano whois figlet p7zip p7zip-full zip unzip rar unrar
RUN apt-get update -yqq && apt-get dist-upgrade -yqq
RUN apt-get install -yqq lubuntu-desktop
RUN apt-get install -yqq tightvncserver
RUN apt-get install -yqq git git-lfs bzr mercurial subversion gnupg gnupg2 tzdata gvfs-bin
RUN apt-get install -yqq gnome-system-monitor tilix
RUN apt-get install -yqq python-apt python-xlib net-tools telnet bash bash-completion lsb-base lsb-release lshw zsh
RUN apt-get install -yqq dconf-cli dconf-editor clipit xclip python3-xlib python3-pip breeze-cursor-theme htop xterm
RUN apt-get autoremove -y
RUN ln -fs /etc/profile.d/vte-2.91.sh /etc/profile.d/vte.sh
#RUN update-alternatives --set x-terminal-emulator $(which tilix)

RUN ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# get additonal software
RUN wget https://raw.githubusercontent.com/sormuras/bach/master/install-jdk.sh;chmod +x install-jdk.sh
RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
RUN wget -O swamp https://github.com/felixb/swamp/releases/latest/download/swamp_amd64;chmod +x swamp
RUN wget -O ideaIU-2019.2.2.tar.gz https://download.jetbrains.com/idea/ideaIU-2019.2.2.tar.gz;tar -xfz ideaIU-2019.2.2.tar.gz
RUN wget -O studio-3t-linux-x64.tar.gz https://download.studio3t.com/studio-3t/linux/2019.5.0/studio-3t-linux-x64.tar.gz; tar -xfz studio-3t-linux-x64.tar.gz

# install ohmyzshell
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# install addiotnal software
RUN dpkg -i session-manager-plugin.deb
RUN ./install-jdk.sh -f 12 --target ./jdk12
ENV PATH="${PATH}:./jdk12/bin"
RUN python3 -m pip install awscli

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

####user section####
# ENV USER developer
# ENV HOME "/home/$USER"

RUN echo 'developer ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo '%developer ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo 'sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo 'www-data ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo '%www-data ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN useradd --create-home --home-dir /home/developer --shell /bin/bash developer && \
  	mkdir /home/developer/.vnc/

RUN usermod -aG sudo developer && \
    usermod -aG root developer && \
    usermod -aG adm developer && \
    usermod -aG www-data developer

COPY vnc.sh /home/developer/.vnc/
COPY xstartup /home/developer/.vnc/

RUN chmod 760 /home/developer/.vnc/vnc.sh /home/developer/.vnc/xstartup && \
  	chown -fR developer:developer /home/developer

# USER "$USER"
###/user section####

####Setup a VNC password####
RUN	echo vncpassw | vncpasswd -f > /home/developer/.vnc/passwd && \
  	chmod 600 /home/developer/.vnc/passwd && \
    chown -fR developer:developer /home/developer

EXPOSE 5901

HEALTHCHECK --interval=60s --timeout=15s \
            CMD netstat -lntp | grep -q '0\.0\.0\.0:5901'

####/Setup VNC####

# CMD ["/home/developer/.vnc/vnc.sh"]
