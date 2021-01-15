#!/bin/bash

############################ Colors ##############################
bold_black='\033[1;30m'
bold_red='\033[1;31m'
bold_green='\033[1;32m'
bold_yellow='\033[1;33m'
bold_dark_blue='\033[1;34m'
bold_purple='\033[1;35m'
bold_light_blue='\033[1;36m'
bold_white='\033[1;37m'
link_cyan='\033[38;1;96m'
reset='\033[0m'
# The -e option of the echo command enables the parsing of the escape sequences
# (often represented by “^[” or “<Esc>” followed by some other characters:
# “\033[<FormatCode>m”). 033 is the octal number for esc ont the ascii table


################## Cheking OS and Arguments #######################
if [[ $OSTYPE = 'darwin20' ]] ; then
	echo -e "\n$bold_red You are not on a VM Linux, you are on a MacOS :/\n"
	exit
fi

if [[ $1 = 'delete' || $1 = 'correction' || $1 = 'check_services' || $1 = '' ]] ; then
	sleep 1
else
	echo -e "\n$bold_red Only accepted arguments:$bold_white delete, correction or check_services$reset\n"
	exit
fi


############################ Welcome #############################
if [[ $1 = '' ]] ; then
	\clear
	echo -e "$bold_white ------------------------------------\n
\033[5;32m WELCOME TO FT_SERVICES\n$reset
 Accepted arguments:\n
$bold_white ./setup.sh delete\n
$bold_white ./setup.sh correction\n
$bold_white ./setup.sh check_services\n
$bold_green <by jfreitas @ Ecole 42>\n
$bold_white ------------------------------------\n"

	echo -e "$bold_red IMPORTANT:"
	echo -e "$bold_white The VM has to have at least 2 CPU cores available. It doesn’t by default, go into VirtualboxVM settings and add another core to it"
	echo -e " 42 VM xUbuntu packets should be installed before run this script:$link_cyan https://pastebin.com/4HnnSUpe"
	echo -e "$bold_yellow If those things are not done, please quit this scrip now and come back when ready!\n$reset"

	echo -e "$bold_green If everything is ready... press 'ENTER' to continue$reset"
	read REPLY
	\clear
	echo -e "$bold_white ------------------------------------"
fi


###################### Configure Minikube IP ######################
# Asking Kubernetes more specifically about its true addresses
function config_cluster_ips()
{
	MINIKUBE_IP="$(kubectl get node -o=custom-columns='DATA:status.addresses[0].address' | sed -n 2p)"
	# -n = will not print anything unless an explicit request to print is found
	# 2p = request to print second line

	clang -o ./srcs/get_service_ip ./srcs/cluster_ip_pool.c
	NGINX_IP=$(./srcs/get_service_ip "$MINIKUBE_IP")
	FTPS_IP=$(./srcs/get_service_ip "$NGINX_IP")
	WORDPRESS_IP=$(./srcs/get_service_ip "$FTPS_IP")
	PHPMYADMIN_IP=$(./srcs/get_service_ip "$WORDPRESS_IP")
	GRAFANA_IP=$(./srcs/get_service_ip "$PHPMYADMIN_IP")
	rm ./srcs/get_service_ip
}


####################### Checking services ########################
if [[ $1 = 'check_services' ]] ; then
	minikube status | grep -c "Running" > /dev/null
	if [[ $? == 0 ]] ; then
		config_cluster_ips
	else
		echo -e "\n$bold_red No cluster set up.\n\n$bold_green To set up a cluster, run:$bold_white ./setup.sh$reset\n"
		exit
	fi
	\clear
	echo -e "\n$bold_white Services:\n"
	echo -e "$bold_white ------------------------------------\n$reset"
	echo -e "$bold_white - cluster IP: $reset$link_cyan$MINIKUBE_IP\n"

	echo -e "$bold_white - nginx:$reset"
	echo -e "    - with redirect to https:             $link_cyan http://$MINIKUBE_IP$reset"
	echo -e "    - reverse proxy to phpmyadmin:        $link_cyan https://$MINIKUBE_IP/phpmyadmin$reset"
	echo -e "    - temporary redirect to wordpress:    $link_cyan https://$MINIKUBE_IP/wordpress$reset"
	echo -e "    - ssh:                                 $>$link_cyan ssh -o StrictHostKeyChecking=no user@$NGINX_IP -p 22$reset"
	echo -e "       > password: password\n"

	echo -e "$bold_white - ftps:$reset                                   $>$link_cyan ftp $MINIKUBE_IP$reset"
	echo -e "    > user: user"
	echo -e "    > password: password"
	echo -e "    - Commands:"
	echo -e "      $>$bold_white send:$reset to download any file from /path/to/ft_services dir to the ftps server$reset"
	echo -e "      $>$bold_white recv:$reset to upload any file from the ftps server to the /path/to/ft_services dir$reset\n"

	echo -e "$bold_white - wordpress:$reset                             $link_cyan http://$MINIKUBE_IP:5050$reset"
	echo -e "    - Connect with adm account            $link_cyan http://$MINIKUBE_IP:5050/wp-login.php$reset"
	echo -e "       > user: jfreitas"
	echo -e "       > password: password\n"

	echo -e "$bold_white - phpmyadmin:$reset                            $link_cyan http://$MINIKUBE_IP:5000$reset\n"
	#echo -e "    > user: user"
	#echo -e "    > password: password\n"

	echo -e "$bold_white - grafana:$reset                               $link_cyan http://$MINIKUBE_IP:3000$reset"
	echo -e "    > user: user"
	echo -e "    > password: password\n"
	echo -e "$bold_white ------------------------------------\n"

#################### Kubernetes web dashboard ####################
	echo -e "$bold_white Dashboard:\n$reset"
	echo -e " If needed, run the command$bold_green minikube dashboard$reset to check the dashboard again!\n$link_cyan"
	# Kubernetes dashboard is a web-based UI for Kubernetes clusters
	# This will help you manage your clusters
	# If Minikube was not being used, a more complex "installation" would have
	# to be done BUT as Minikube has integrated support for the Kubernetes
	# Dashboard UI, just run:
	sudo minikube dashboard
	# If you don’t want to open a web browser, the dashboard command can also
	# simply emit a URL: minikube dashboard --URL
fi


###################### Deleting everything #######################
if [[ $1 = 'delete' ]] ; then
	minikube status | grep -c "Running" > /dev/null
	if [[ $? == 0 ]] ; then
		config_cluster_ips
	else
		echo -e "\n$bold_red No cluster set up.\n\n$bold_green To set up a cluster, run:$bold_white ./setup.sh$reset\n"
		exit
	fi
	\clear
	echo -ne "\n$bold_yellow Unset IP addresses variables...$reset"

	for path in srcs/services/nginx/basic_nginx.conf
	do
		sed -i 's/'$WORDPRESS_IP'/WORDPRESS_IP/g' $path
		sed -i 's/'$PHPMYADMIN_IP'/PHPMYADMIN_IP/g' $path
		sed -i 's/'$GRAFANA_IP'/GRAFANA_IP/g' $path
		echo -ne "\nIP variables were unset inside the file $path"
	done

	for path in srcs/services/nginx/index.html
	do
		sed -i 's/'$MINIKUBE_IP'/MINIKUBE_IP/g' $path
		echo -ne "\nMINIKUBE_IP variable was unset inside the file $path"
	done

	for path in srcs/services/mysql/wordpress.sql
	do
		sed -i 's/'$WORDPRESS_IP'/WORDPRESS_IP/g' $path
		echo -ne "\nWORDPRESS_IP variable was unset inside the file $path"
	done

	for path in srcs/services/grafana/grafana.ini
	do
		sed -i 's/'$MINIKUBE_IP'/MINIKUBE_IP/g' $path
		echo -ne "\nMINIKUBE_IP variable was unset inside the file $path \n"
	done

	for path in srcs/yaml_files/loadbalancer_metallb.yaml
	do
		sed -i 's/'$NGINX_IP'/'CLUSTER_POOL_BEG'/g' $path
		sed -i 's/'$GRAFANA_IP'/'CLUSTER_POOL_END'/g' $path
	done


	echo -ne "\n$bold_yellow Deleting all services...\n$reset"
	# delete this part if minikube tunnel is used
	kubectl delete -f srcs/yaml_files/loadbalancer_metallb.yaml


	SERVICES="nginx ftps mysql wordpress phpmyadmin influxdb grafana telegraf"
	# for loop = Expand words (see Shell Expansions), and execute commands once
	# for each member in the resultant list
	for service in $SERVICES
	do
		rm $service.txt
		kubectl delete -f "srcs/yaml_files/services_yaml/$service.yaml"
		echo ""
	done

	echo -ne "\n$bold_yellow Deleting Minikube...\n$reset"
	sudo minikube delete

	echo -ne "\n$bold_yellow Deleting Minikube Docker image...\n$reset"
	minikube_image=$(docker images | grep "minikube" | awk '{ print $3 }')
	docker rmi $minikube_image

	echo -ne "\n$bold_green Done!\n\n$reset"
	exit


########################### Correction ###########################
elif [[ $1 = 'correction' ]] ; then
	minikube status | grep -c "Running" > /dev/null
	if [[ $? == 0 ]] ; then
		\clear
	else
		echo -e "\n$bold_red No cluster set up.\n\n$bold_green To set up a cluster, run:$bold_white ./setup.sh$reset\n"
		exit
	fi
	SERVICES="nginx ftps mysql wordpress phpmyadmin influxdb grafana telegraf"

	echo -e "\n$bold_white- Checking if services exist and have the correct name:"
	for service in $SERVICES
	do
		kubectl get pods | grep $service- 2>&1 > /dev/null
		if [ $? -ne 0 ]
		then
			echo -e "$bold_red ERROR: service $service is missing or was not named correctly$reset"
			exit
		else
			echo -e "$bold_green $service  ✅$reset"
		fi
	done

	sleep 3
	echo -e "\n$bold_white- Checking if pods are running:"
	for service in $SERVICES
	do
		RUNNING=`kubectl get pods | grep $service | tr -s ' ' | cut -d ' ' -f 3`
		if [ "$RUNNING" = "Running" ]
		then
			echo -e "$bold_green $service is running$reset"
		else
			echo -e "$bold_red ERROR: $service is not running$reset"
			exit
		fi
	done

	sleep 3
	echo -e "\n$bold_white- Checking if services have been restarted:"
	for service in $SERVICES
	do
		RESTARTS=`kubectl get pods | grep $service | tr -s ' ' | cut -d ' ' -f 4`
		if [ $RESTARTS -eq 0 ]
		then
			echo -e "$bold_green $service: 0 RESTARTS$reset"
		else
			echo -e "$bold_yellow $service restarted $RESTARTS time(s)$reset"
		fi
		done

	sleep 3
	echo -e "\n$bold_white- Killing all the processes:"
	for service in $SERVICES
	do
		POD_NAME=`kubectl get pods | grep $service | cut -d ' ' -f 1`
		case $service in
			nginx)
			kubectl exec $POD_NAME -- pkill sshd 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green SSH killed$reset"
			else
				echo -e "$bold_red SSH not killed$reset"
			fi
			sleep 5
			kubectl exec $POD_NAME -- pkill nginx 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green $service killed$reset"
			else
				echo -e "$bold_red $Sservice not killed$reset"
			fi
			;;
			telegraf)
			kubectl exec $POD_NAME -- pkill telegraf 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green $service killed$reset"
			else
				echo -e "$bold_red $service not killed$reset"
			fi
			;;
			ftps)
			kubectl exec $POD_NAME -- pkill vsftpd 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green $service killed$reset"
			else
				echo -e "$bold_red $service not killed$reset"
			fi
			;;
			mysql)
			kubectl exec $POD_NAME -- pkill mysqld 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green $service killed$reset"
			else
				echo -e "$bold_red $service not killed$reset"
			fi
			;;
			influxdb)
			kubectl exec $POD_NAME -- pkill influxd 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green $service killed$reset"
			else
				echo -e "$bold_red $service not killed$reset"
			fi
			;;
			grafana)
			kubectl exec $POD_NAME -- pkill grafana 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green $service killed$reset"
			else
				echo -e "$bold_red $service not killed$reset"
			fi
			;;
			wordpress)
			kubectl exec $POD_NAME -- pkill php-fpm 2>&1 > /dev/null
			sleep 5
			kubectl exec $POD_NAME -- pkill nginx 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green $service killed$reset"
			else
				echo -e "$bold_red $service not killed$reset"
			fi
			;;
			phpmyadmin)
			kubectl exec $POD_NAME -- pkill php-fpm 2>&1 > /dev/null
			sleep 5
			kubectl exec $POD_NAME -- pkill nginx 2>&1 > /dev/null
			if [ $? -ne 1 ]
			then
				echo -e "$bold_green $service killed$reset"
			else
				echo -e "$bold_red $service not killed$reset"
			fi
			;;
			*)
			;;
		esac
	done
	sleep 15
	echo -e "\n$bold_white- Check if there are any pods that can't restart:$reset"
	echo -e " Command:$bold_green kubectl get pods$reset will be executed now:$reset\n"
	sleep 5
	kubectl get pods
	echo -e "\n$bold_white If needed, run the same command again!$reset\n"
	exit
fi


################### Install kubernetes kubectl ###################
# The Kubernetes command-line tool, kubectl, allows you to run commands
# against Kubernetes clusters
# This script will install it if it's not already installed
# Normaly kubectl is already installed on the 42 Mac and the VM
# <which> command will return 0 if the specified command is found and executable
echo -ne "\n$bold_yellow Checking if Kubectl is installed...\n\n"
# OBS: if color is between {} (ex: ${bold_green}, then no space is needed
which kubectl > /dev/null
# Another option so which is not needed: if [[ ! -d "/PATH"]] ; then
if [[ $? == 0 ]] ; then
	echo -ne "$bold_green Kubectl is already installed!\n\n"
	echo -e "$bold_white ------------------------------------\n"
else
	echo -ne "$bold_red Kubectl is not installed.\n$bold_green Installing...$bold_white\n"
	sudo rm -rf /usr/local/bin/kubectl
	curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
	# Make the kubectl binary executable
	chmod +x ./kubectl
	# Add the Minikube executable to your path
	sudo mv ./kubectl /usr/local/bin/kubectl
	echo -ne "\n$bold_green Kubectl installed!\n\n"
	echo -e "$bold_white ------------------------------------\n"
fi


######################### Install MetalLB #########################
function install_metallb()
{
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
	# On first install only
	# The memberlist secret contains the secretkey (from openssl) to encrypt
	# the communication between speakers for the fast dead node detection
	kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

	config_cluster_ips
	for path in srcs/yaml_files/loadbalancer_metallb.yaml
	do
		sed -i 's/'CLUSTER_POOL_BEG'/'$NGINX_IP'/g' $path
		sed -i 's/'CLUSTER_POOL_END'/'$GRAFANA_IP'/g' $path
		echo -ne "\n$bold_green CLUSTER_POOL_BEG and CLUSTER_POOL_END variables inside $path file were replaced\n\n$reset"
	done

	kubectl apply -f srcs/yaml_files/loadbalancer_metallb.yaml
}
### Minikube tunnel may also be another option


####################### Change IP variables #######################
function edit_ip_variable()
{
	config_cluster_ips
### Nginx redirections and index
	if [[ $1 = 'nginxredirecions' ]] ; then
		for path in srcs/services/nginx/basic_nginx.conf
		do
			sed -i.bak 's/WORDPRESS_IP/'$WORDPRESS_IP'/g' $path
			sed -i.bak 's/PHPMYADMIN_IP/'$PHPMYADMIN_IP'/g' $path
			sed -i.bak 's/GRAFANA_IP/'$GRAFANA_IP'/g' $path
		done

		for path in srcs/services/nginx/index.html
		do
			sed -i 's/MINIKUBE_IP/'$MINIKUBE_IP'/g' $path
		done
	fi

### MySQL wordpress dump for mysql
	if [[ $1 = 'wordpressdump' ]] ; then
		for path in srcs/services/mysql/wordpress.sql
		do
			sed -i.bak 's/WORDPRESS_IP/'$WORDPRESS_IP'/g' $path
		done
	fi

### Grafana
	if [[ $1 = 'grafana' ]] ; then
		for path in srcs/services/grafana/grafana.ini
		do
			sed -i 's/MINIKUBE_IP/'$MINIKUBE_IP'/g' $path
		done
	fi
	sleep 3
}


####################### Build Docker images #######################
function build_docker_images()
{
############################## nginx ##############################
	# A Nginx server listening on ports 80 and 443
	# Port 80 will be in http and should be a systematic redirection of type 301 to 443
	# Port 443 will be in https
	# The page displayed does not matter (it'll be index.php in this case)
	# You must be able to access the Nginx container by logging into SSH
	edit_ip_variable 'nginxredirecions'
	echo -ne "$bold_green IP variables inside ./srcs/services/nginx/basic_nginx.conf and index.html files were replaced\n\n"

	echo -ne "$bold_yellow Building a Nginx server image...\n$reset"
	docker build -t nginx srcs/services/nginx/ > nginx.txt
	# built a Docker image from a Dockerfile
	# The tag -t (tag) will be basically the name of the image
	# LAST parameter tells docker build to look for the Dockerfile in the directory specified

	echo -ne "\n$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"
	# Necessary so SSH can run
	ssh-keygen -f "/home/user42/.ssh/known_hosts" -R "$NGINX_IP" &> /dev/null

############################### ftps #############################
	# A FTPS server listening on port 21
	echo -ne "$bold_yellow Building a FTPS server image...\n$reset"
	docker build -t ftps srcs/services/ftps/ > ftps.txt

	echo -ne "\n$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

############################### mysql ############################
	# MySQL database server exposed on port 3306
	edit_ip_variable 'wordpressdump'
	echo -ne "$bold_green WORDPRESS_IP variable inside ./srcs/services/mysql/wordpress.sql file was replaced\n\n"

	echo -ne "$bold_yellow Building a MySQL database image...\n$reset"
	docker build -t mysql srcs/services/mysql/ > mysql.txt

	echo -ne "\n$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

############################# wordpress ##########################
	# A WordPress website listening on port 5050, which will work with a MySQL database
	# Both services have to run in separate containers
	# The WordPress website will have several users and an administrator
	echo -ne "$bold_yellow Building a WordPress website image...\n\n$reset"
	docker build -t wordpress srcs/services/wordpress/ > wordpress.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

############################ phpmyadmin ##########################
	# PhpMyAdmin, listening on port 5000 and linked with the MySQL database
	echo -ne "$bold_yellow Building a PhpMyAdmin tool image...\n\n$reset"
	docker build -t phpmyadmin srcs/services/phpmyadmin/ > phpmyadmin.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

############################## influxdb ##########################
	# Influxdb listening on port 8086
	echo -ne "$bold_yellow Building a Influxdb database image...\n\n$reset"
	docker build -t influxdb srcs/services/influxdb/ > influxdb.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

############################# grafana ############################
	# A Grafana platform, listening on port 3000, linked with an InfluxDB database
	# Grafana will be monitoring all your containers.
	# You must create one dashboard per services
	edit_ip_variable 'grafana'
	echo -ne "$bold_green MINIKUBE_IP variable inside ./srcs/services/grafana/grafana.ini file was replaced\n\n"

	echo -ne "$bold_yellow Building a Grafana web dashboard image...\n\n$reset"
	docker build -t grafana srcs/services/grafana/ > grafana.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

############################# telegraf ############################
	# Telegraf will collect metrics from a variety of different systems and
	# push to InfluxDB so they can be later analyzed in Grafana
	echo -ne "$bold_yellow Building a Telegraf image...\n\n$reset"
	docker build -t telegraf srcs/services/telegraf/ > telegraf.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"
}


#################### Create pods and services #####################
function create_pods_services()
{
	echo -ne "$bold_yellow Creating pods and services...\n\n$reset"

	SERVICES="nginx ftps mysql wordpress phpmyadmin influxdb telegraf grafana"

	for service in $SERVICES
	do
		kubectl apply -f srcs/yaml_files/services_yaml/$service.yaml
		# kubectl apply -f will create a service using the definition in a yaml file
		echo ""
	done

	echo -ne "\n$bold_green Pods and services created!\n\n"
	echo -e "$bold_white ------------------------------------\n"
}


################## Update and install Packages ###################
echo -ne "$bold_yellow Updating and installing packages (it may take some seconds)...\n\n"

echo -ne "$bold_dark_blue Sudo privileges may be necessary to update and install Linux packages.\n"
echo -ne " If requested, please type the ${bold_white}$(whoami) password ${bold_dark_blue}down below!\n \n$bold_white"
sleep 3
# Modifying the user account, adding the user whoami to the group sudo
# Group is a list of supplementary groups which the user is also a member of
sudo usermod -aG sudo $(whoami) &> /dev/null

sudo apt-get -y update &> /dev/null
sudo apt-get -y upgrade &> /dev/null

echo -e "$bold_green Done!\n"
echo -e "$bold_white ------------------------------------\n"


##################### Install Minikube #######################
# Minikube is a tool that makes it easy to run Kubernetes locally
# This script will install it if it's not already installed
# Normaly Minikube is already installed on the 42 VM

# If flag --vm-driver=docker is used on VM, virtualization is not necessary
function install_minikube()
{
	echo -ne "$bold_red Minikube is not updated or installed.\n$bold_green Installing...$reset\n\n"
	sudo rm -rf /usr/local/bin/minikube
	curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	# Make the minikube binary executable
	chmod +x ./minikube
	# Add the Minikube executable to your path
	sudo mv ./minikube /usr/local/bin/minikube
	## On kubernetes website it shows to add the executable as down below
	## but it worked just with the <mv> command
	# sudo mkdir -p /usr/local/bin/
	# sudo install minikube /usr/local/bin/
	echo -ne "\n$bold_green Minikube installed!\n\n"
	echo -e "$bold_white ------------------------------------\n"
}

echo -ne "$bold_yellow Checking if Minikube is updated and/or installed...\n\n"
which minikube > /dev/null
if [[ $? == 0 ]] ; then
	version_checker=$(minikube update-check | awk '{ print $2 }' | uniq | wc -l)
	if [[ $version_checker == 2 ]] ; then
		install_minikube
	fi
	echo -ne "$bold_green Minikube is already installed with the most updated version!\n\n"
	echo -e "$bold_white ------------------------------------\n"
else
	install_minikube
fi


###################### Install Docker Engine #####################
# Since normally Docker Engine is already installed on the 42 VM Linux,
# there is no need to install it. But as ctrl+c ctrl+v may be
# not enabled on the VM of the peer evaluator, it's good to to:
# 1. Uninstall old versions (docker, docker.io or docker-engine)
# 2. set up the repository
# 3. install the new version (docker-ce)
# 4. Manage Docker as a non-root user (since Docker runs as the root user)
# 5. Configure Docker to start on boot
function install_docker()
{
	# uninstall older versions:
	sudo apt-get -y remove docker docker-engine docker.io containerd runc &> /dev/null
	echo -ne "\n$bold_yellow Setting up the repository...$bold_whiten\n\n"
	# install packages to allow apt to use a repository over HTTPS:
	sudo apt-get install apt-transport-https ca-certificates gnupg-agent software-properties-common &> /dev/null
	# Add Docker’s official GPG key:
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null
	echo -ne "$bold_dark_blue Verify on the second line if you have the key with this fingerprint:\n"
	echo -ne "$bold_white 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88$reset\n"
	echo -ne "$bold_red If not, please exit and report to jfreitas\n"
	echo -ne "\n$bold_yellow Printing key...$bold_white\n"
	sudo apt-key fingerprint 0EBFCD88
	# set up the stable repository:
	sudo add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable" &> /dev/null
	echo -ne "\n$bold_green Everything seems right, so:\n"
	echo -ne "$bold_yellow Intalling newer Docker version...$bold_white\n"
	# The Docker Engine package is now called docker-ce
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io &> /dev/null

	echo -ne "\n$bold_green Docker installed!\n\n"
	echo -e "$bold_white ------------------------------------\n"
}

function sudo_docker()
{
	# Manage Docker as a non-root user:
	# For some reason, by default, on 42's VM you can't run Docker without
	# sudo and Minikube will not work if that's the case. So let's fix that:
	sudo groupadd docker &> /dev/null
	sudo usermod -aG docker $(whoami) &> /dev/null
	newgrp docker &
	# Configure Docker to start on boot:
	# systemctl command is basically a more powerful version of service (used on linux)
	sudo systemctl enable docker &> /dev/null
	sudo systemctl start docker &> /dev/null
}

echo -ne "$bold_yellow Checking if Docker is installed and up to date...\n"
DOCKER_I0=$(whereis -b -B /usr/share -f docker)
WHICH_DOCKER=$(which docker)
if [[ $DOCKER_IO = 'docker: /usr/share/docker.io' ]] ; then
	echo -ne "$bold_red Older version called docker.io is installed!\n\n"
	# Older versions of Docker were called docker, docker.io or
	# docker-engine. If these are installed, uninstall them:
	echo -ne "\n$bold_yellow Deleting older version...\n\n"
	install_docker
	sudo_docker
elif [[ $WHICH_DOCKER != '/usr/bin/docker' ]] ; then
	echo -ne "\n$bold_red Docker is not installed!\n"
	install_docker
	sudo_docker
else
	sudo_docker
	echo -ne "\n$bold_green Docker is already the newer version!\n\n"

	echo -e "$bold_white ------------------------------------\n"
fi


######################### Start Minikube #########################
# Checking if cluster is running, else delete cluster
echo -ne "$bold_yellow Starting Minikube cluster...\n\n$reset"
minikube config set driver docker &> /dev/null

# if any cluster already exists, delete everything
minikube status | grep -c "Running" > /dev/null
if [[ $? == 0 ]] ; then
	echo -ne "$bold_yellow If any Minikube cluster is running, it will be deleted, together with it's Docker images and containers.\n\n"
	./setup.sh delete
fi

# For VM Linux: launch minikube with Docker as the driver
minikube start --vm-driver=docker --cpus=2

if [[ $? == 0 ]] ; then
	minikube addons enable metrics-server > /dev/null
	echo "🌟  The 'metrics-server' addon is enabled"
	minikube addons enable dashboard > /dev/null
	echo "🌟  The 'dashboard' addon is enabled"
	eval $(sudo minikube docker-env)
	minikube status | grep -c "Running" > /dev/null
	if [[ $? == 0 ]] ; then
		config_cluster_ips
		echo -ne "\n$bold_green Minikube cluster started!\n\n"
		echo -e "$bold_white ------------------------------------\n"
	fi
else
	sudo minikube delete > /dev/null
	echo -ne "$bold_red Error: Minikube cluster NOT started :( Review script and re-start minikube with --alsologtostderr -v=1 to debug crashes\n\n"
	exit
fi


##################### Load Balancer MetalLB ######################
echo -ne "$bold_yellow Installing MetalLB LoadBalancer...\n\n$reset"
install_metallb
echo -ne "\n$bold_green Done!\n\n"
echo -e "$bold_white ------------------------------------\n"


############################ Services ############################
build_docker_images
create_pods_services


########################### Correction ###########################
echo -e "$bold_white Press 'ENTER' to see services for correction$reset"
read REPLY

./setup.sh check_services
