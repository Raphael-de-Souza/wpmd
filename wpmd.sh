#!/usr/bin/env sh

logFunc(){
cmd=$1
line=$2
{ date; echo " - Line: ${line} - "; ${cmd}; } |& sed ':a;N;s/\n/ /;ba' |& sudo tee -a ./wpmd.log
}

#Param to fix the x and q problem with borders in dialog
export NCURSES_NO_UTF8_ACS=1

#Get the name of Linux distro
version=$(hostnamectl | grep -oP "(?<=\Operating System:\s)(\w+)")

#Update the Linux
#sudo apt-get -y update

#Verify Linux distro
echo $version
case $version in
	"Ubuntu"|"Debian")
		#sudo apt-get -y install dialog
		#gdialog --menu "Plese select:" 0 0 0 1 "Wizard install" 2 "Personalized install"
		
		modeSel=$(dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
				 --clear \
				 --cancel-label "Exit" \
				 --menu "Please, select the mode:" 0 0 0 \
					"1" "Wizard" \
					"2" "Personalized" --output-fd 1)
		if [[ ${modeSel} = 1 ]];
		then
			dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
			       --yesno "Want create a Swap file (It's good if you have below 4GB of RAM)?" 5 75
			swpSel=$?
			if [ $swpSel = 0 ];
			then
				while [[ $swpFile = "" ]]
				do	
				swpFile=$(dialog --stdout --title "Please, define the folder and the name for the Swap file (or press enter to default values):" \
						 --fselect /swapfile 20 0)
				done
				while [[ $swpLen = "" ]]
				do
				swpLen=$(dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
						--clear \
						--inputbox "Please, define the lenght for the Swap file (It's good a minimum of 2GB):" 16 51 --output-fd 1) 
				done
				logFunc "fallocate -l ${swpLen}G ${swpFile}" $LINENO
				logFunc "chmod 600 ${swpFile}" $LINENO
				logFunc "mkswap ${swpFile}" $LINENO
				logFunc "swapon ${swpFile}" $LINENO
				logFunc "$(echo ${swpFile}' none swap sw 0 0' | sudo tee -a /etc/fstab)" $LINENO
				dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
                                       --msgbox "Created a Swap file with the following configurations:\n\nPath:${swpFile}\nLenght:${swpLen}GB" 9 50
			fi
			
			dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
			       --yesno "Want to install Docker?" 5 0
			dockerSel=$?
			if [ ${dockerSel} = 0 ];
			then
				sudo bash < <(curl -s https://get.docker.com/)
				sudo usermod -aG docker $USER
				sudo docker container ls
				sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
				sudo chmod 755 /usr/local/bin/docker-compose
				dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
                                        --msgbox "$(sudo docker --version)\n\nAnd\n\n$(sudo docker-compose --version)\n\nInstaled!" 11 50
			fi
			
			dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
			       --yesno "Want to install Wordpress and MySQL Docker Containers?" 5 0
			wpSel=$?
			if [ ${wpSel} = 0 ];
			then
				sudo apt install -y git
				wpFolder=$(dialog --stdout --title "Please, define the folder and the name to install Wordpress and MySQL containers (or press enter to default values):" \
                                                 --fselect /wp-mysql-containers 20 0)
			        sudo git clone https://github.com/chrisbmatthews/wordpress-docker-compose.git $wpFolder
	
				phpConf=$(dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
                                       		--stdout --form "Setup the php.conf.ini (press enter to default values):" 12 41 5 \
                                                       "file_uploads (On/Off):"     1 1 "On"       1 26 10 0 \
						       "memory_limit (MB): "        2 1 "500"      2 26 10 0 \
                                                       "upload_max_filesize (MB): " 3 1 "30" 3 26 10 0 \
                                                       "post_max_size (MB): "       4 1 "30"   4 26 10 0 \
				                       "max_execution_time (ms): "  5 1 "600" 5 26 10 0 --output-fd 1)
				echo -e "file_uploads = "$(echo $phpConf | grep -oP "^(?:\w+ ){0}\K\w+")\\n"memory_limit = "$(echo $phpConf | grep -oP "^(?:\w+ ){1}\K\w+")M\\n"upload_max_filesize = "$(echo $phpConf | grep -oP "^(?:\w+ ){2}\K\w+")M\\n"post_max_size = "$(echo $phpConf | grep -oP "^(?:\w+ ){3}\K\w+")M\\n"max_execution_time = "$(echo $phpConf | grep -oP "^(?:\w+ ){4}\K\w+")| sudo tee $wpFolder/config/php.conf.ini
				

				envConf=$(dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
                                                 --stdout --form "Setup the enviroment (press enter to default values):" 12 41 5 \
                                                       "IP: "     	    1 1 "127.1.1.1" 1 26 10 0 \
                                                       "DB_NAME: " 	    2 1 "wordpress" 2 26 10 0 --output-fd 1)
				echo -e "IP="$(echo $envConf | grep -oP "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}")\\n"DB_NAME="$(echo $envConf | grep -oP "[^\s]*$") | sudo tee $wpFolder/.env
				while [[ $passDb = "" ]]
				do
				passDb=$(dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
						--clear \
						--insecure \
						--passwordbox "Define a MySQL root password (DB_ROOT_PASSWORD): " 10 35 --output-fd 1)
				done
				sed '/DB_ROOT_PASSWORD/d' $wpFolder/.env | sudo tee  $wpFolder/.env
				echo "DB_ROOT_PASSWORD="$passDb | sudo tee -a $wpFolder/.env
				cd $wpFolder
				docker-compose up -d
			fi
		fi
		if [[ ${modeSel} = 2 ]];
		then
			modeSel=$(dialog --backtitle "WORDPRESS + MYSQL DOCKER CONTAINERS - INSTALATION AND CONFIGURATION" \
					 --clear \
					 --cancel-label "Exit" \
					 --menu "Please, select:" 0 0 0 \
						"1" "Make Swap file" \
						"2" "Install Docker" \
						"3" "Install Wordpress and MySQL Docker Containers" \
						"4" "Configure MySQL" --output-fd 1)
		fi
		;;
	"CentOS"|"Redhat")
		yum -y install dialog
		;;
	"Suse")
		zypper -y install dialog
		;;
	*)
esac


