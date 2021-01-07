#!/bin/bash

# This script will setup all your applications for the VM Linux or MacOS.

# The VM has to have at least 2 CPU cores available. It doesn’t by default, go
# into VirtualboxVM settings and add another core to it.

############################ Colors ##############################
bold_black='\033[1;30m'
bold_red='\033[1;31m'
bold_green='\033[1;32m'
bold_yellow='\033[1;33m'
bold_dark_blue='\033[1;34m'
bold_purple='\033[1;35m'
bold_light_blue='\033[1;36m'
bold_white='\033[1;37m'
bold_cyan_filled='\033[1;7;96m'
reset='\033[0m'
# The -e option of the echo command enables the parsing of the escape sequences
# (often represented by “^[” or “<Esc>” followed by some other characters:
# “\033[<FormatCode>m”). 033 is the octal number for esc ont the ascii table


############################ Welcome #############################
if [[ ! $1 ]] ; then
	\clear
echo -e "$bold_white ------------------------------------\n
\033[5;32m WELCOME TO FT_SERVICES\n$reset
$bold_dark_blue For VM Linux:
$bold_white ./setup.sh vm$bold_green to run\n$bold_white ./setup.sh delete vm$bold_red to delete everything \n
$bold_dark_blue For 42 Mac:
$bold_white ./setup.sh mac$bold_green to run\n$bold_white ./setup.sh delete mac$bold_red to delete everything \n
$bold_green <by jfreitas @ Ecole 42>\n
$bold_white ------------------------------------"
	exit
fi


####################### Checking Arguments #######################
if [[ $1 !=  'mac' && $1 != 'vm' && $1 != 'delete' ]] ; then
	echo -e "\n$bold_red Missing$bold_green mac$bold_red,$bold_green vm$bold_red or$bold_green delete$bold_red as second argument!\n"
	exit
fi


###################### Configure Minikube IP ######################
# Asking Kubernetes more specifically about its true addresses, because
# in some cases, calling minikube ip (which is heavily used in this project)
# will return 172.0.0.1 on Linux. However, your cluster will normally be
# discoverable somewhere around 172.17.0.2
function config_cluster_ips()
{
	MINIKUBE_IP="$(kubectl get node -o=custom-columns='DATA:status.addresses[0].address' | sed -n 2p)"
	# -n = will not print anything unless an explicit request to print is found
	# 2p = request to print second line
	#NGINX_IP=192.168.49.3
	#FTPS_IP=192.168.49.4
	WORDPRESS_IP=192.168.49.5
	PHPMYADMIN_IP=192.168.49.6
	GRAFANA_IP=192.168.49.7
}


###################### Deleting everything #######################
if [[ $1 = 'delete' ]] ; then
	\clear
	config_cluster_ips
	echo -ne "\n$bold_yellow Unset IP addresses variables...$reset"

	for path in srcs/services/1_nginx_server/basic_nginx.conf
	do
		sed -i 's/'$WORDPRESS_IP'/WORDPRESS_IP/g' $path
		sed -i 's/'$PHPMYADMIN_IP'/PHPMYADMIN_IP/g' $path
		sed -i 's/'$GRAFANA_IP'/GRAFANA_IP/g' $path
		echo -ne "\nIP variables were unset inside the file $path"
	done

	for path in srcs/services/1_nginx_server/index.html
	do
		sed -i 's/'$MINIKUBE_IP'/MINIKUBE_IP/g' $path
		echo -ne "\nMINIKUBE_IP variable was unset inside the file $path"
	done

	for path in srcs/services/3_mysql_database/wordpress.sql
	do
		sed -i 's/172.17.0.7/WORDPRESS_IP/g' $path
		sed -i 's/192.168.49.5/WORDPRESS_IP/g' $path
		echo -ne "\nWORDPRESS_IP variable was unset inside the file $path"
	done

	for path in srcs/services/7_grafana_influxdblinked/grafana.ini
	do
		sed -i 's/'$MINIKUBE_IP'/MINIKUBE_IP/g' $path
		echo -ne "\nMINIKUBE_IP variable was unset inside the file $path \n"
	done

	echo -ne "\n$bold_yellow Deleting all services...\n$reset"
	# delete this part if minikube tunnel is used
	if [[ $OSTYPE = 'linux-gnu' ]] ; then
		kubectl delete -f srcs/yaml_files/loadbalancer_metallb.yaml
	elif [[ $OSTYPE = 'darwin20' ]] ; then
		kubectl delete -f srcs/yaml_files/loadbalancer_metallb_mac.yaml
	fi


	SERVICES="1_nginx_server 2_ftps_server 3_mysql_database 4_wordpress_mysqllinked 5_phpmyadmin_mysqllinked 6_influxdb_database 7_grafana_influxdblinked 8_telegraf_influxdblinked"
	# for loop = Expand words (see Shell Expansions), and execute commands once
	# for each member in the resultant list
	for service in $SERVICES
	do
		rm $service.txt
		kubectl delete -f "srcs/yaml_files/services_yaml/$service.yaml"
		echo ""
	done

	if [[ $2 = 'vm' ]] ; then
		echo -ne "\n$bold_yellow Deleting Minikube...\n$reset"
		sudo minikube delete

		echo -ne "\n$bold_yellow Deleting Minikube Docker image...\n$reset"
		minikube_image=$(docker images | grep "minikube" | awk '{ print $3 }')
#		minikube_image=$(docker images | awk 'NR==2 { print $3 }')
		docker rmi $minikube_image
	fi

	if [[ $2 = 'mac' ]] ; then
		echo -ne "\n$bold_yellow Deleting Minikube...\n$reset"
		minikube delete

		echo -ne "\n$bold_yellow Deleting VirtualBox VM Minikube...\n$reset"
		vboxmanage controlvm minikube poweroff
		vboxmanage unregistervm --delete minikube
	fi

	echo -ne "\n$bold_green Done!\n\n"
	exit
fi


################### Install kubernetes kubectl ###################
# The Kubernetes command-line tool, kubectl, allows you to run commands
# against Kubernetes clusters
# This script will install it if it's not already installed
# Normaly kubectl is already installed on the 42 Mac and the VM
# <which> command will return 0 if the specified command is found and executable
if [[ $1 = 'mac' && $OSTYPE = 'darwin20' || $1 = 'vm' && $OSTYPE = 'linux-gnu' ]] ; then
	\clear
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
		if [[ $1 = 'mac' && $OSTYPE = 'darwin20' ]] ; then
			curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
		fi
		if [[ $1 = 'vm' && $OSTYPE = 'linux-gnu' ]] ; then
			curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
		fi
		# Make the kubectl binary executable
		chmod +x ./kubectl
		# Add the Minikube executable to your path
		sudo mv ./kubectl /usr/local/bin/kubectl
		echo -ne "\n$bold_green Kubectl installed!\n\n"
		echo -e "$bold_white ------------------------------------\n"
	fi
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

	if [[ $OSTYPE = 'darwin20' ]] ; then
		kubectl apply -f srcs/yaml_files/loadbalancer_metallb_mac.yaml
	elif [[ $OSTYPE = 'linux-gnu' ]] ; then
		kubectl apply -f srcs/yaml_files/loadbalancer_metallb.yaml
	fi
}
### Minikube tunnel may also be another option


####################### Change IP variables #######################
function edit_ip_variable()
{
	config_cluster_ips

### Nginx redirections and index
	if [[ $1 = 'nginxredirecions' ]] ; then
		for path in srcs/services/1_nginx_server/basic_nginx.conf
		do
			sed -i.bak 's/WORDPRESS_IP/'$WORDPRESS_IP'/g' $path
			sed -i.bak 's/PHPMYADMIN_IP/'$PHPMYADMIN_IP'/g' $path
			sed -i.bak 's/GRAFANA_IP/'$GRAFANA_IP'/g' $path
		done

		for path in srcs/services/1_nginx_server/index.html
		do
			sed -i 's/MINIKUBE_IP/'$MINIKUBE_IP'/g' $path
		done
	fi

### MySQL wordpress dump for mysql
	if [[ $1 = 'wordpressdump' ]] ; then
		for path in srcs/services/3_mysql_database/wordpress.sql
		do
			sed -i.bak 's/WORDPRESS_IP/'$WORDPRESS_IP'/g' $path
		done
	fi

### Grafana
	if [[ $1 = 'grafana' ]] ; then
		for path in srcs/services/7_grafana_influxdblinked/grafana.ini
		do
			sed -i 's/MINIKUBE_IP/'$MINIKUBE_IP'/g' $path
		done
	fi
	sleep 3
}


####################### Build Docker images #######################
function build_docker_images()
{
######################### 1_nginx_server #########################
	# A Nginx server listening on ports 80 and 443
	# Port 80 will be in http and should be a systematic redirection of type 301 to 443
	# Port 443 will be in https
	# The page displayed does not matter (it'll be index.php in this case)
	# You must be able to access the Nginx container by logging into SSH
	edit_ip_variable 'nginxredirecions'
	echo -ne "$bold_green IP variables inside ./srcs/services/1_nginx_server/basic_nginx.conf file were replaced\n\n"

	echo -ne "$bold_yellow Building a Nginx server image...\n$reset"
	docker build -t 1_nginx_server srcs/services/1_nginx_server/ > 1_nginx_server.txt
	# built a Docker image from a Dockerfile
	# The tag -t (tag) will be basically the name of the image
	# LAST parameter tells docker build to look for the Dockerfile in the directory specified

	echo -ne "\n$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

########################## 2_ftps_server #########################
	# A FTPS server listening on port 21
	echo -ne "$bold_yellow Building a FTPS server image...\n$reset"
	docker build -t 2_ftps_server srcs/services/2_ftps_server/ > 2_ftps_server.txt

	echo -ne "\n$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

######################### 3_mysql_database #######################
	# MySQL database server exposed on port 3306
	edit_ip_variable 'wordpressdump'
	echo -ne "$bold_green WORDPRESS_IP variable inside ./srcs/services/3_mysql_database/wordpress.sql file was replaced with the address $WORDPRESS_IP\n\n"

	echo -ne "$bold_yellow Building a MySQL database image...\n$reset"
	docker build -t 3_mysql_database srcs/services/3_mysql_database/ > 3_mysql_database.txt

	echo -ne "\n$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

###################### 4_wordpress_mysqllinked ###################
	# A WordPress website listening on port 5050, which will work with a MySQL database
	# Both services have to run in separate containers
	# The WordPress website will have several users and an administrator
	echo -ne "$bold_yellow Building a WordPress website image...\n\n$reset"
	docker build -t 4_wordpress_mysqllinked srcs/services/4_wordpress_mysqllinked/ > 4_wordpress_mysqllinked.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

##################### 5_phpmyadmin_mysqllinked ###################
	# PhpMyAdmin, listening on port 5000 and linked with the MySQL database
	echo -ne "$bold_yellow Building a PhpMyAdmin tool image...\n\n$reset"
	docker build -t 5_phpmyadmin_mysqllinked srcs/services/5_phpmyadmin_mysqllinked/ > 5_phpmyadmin_mysqllinked.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

######################## 6_influxdb_database #####################
	# Influxdb listening on port 8086
	echo -ne "$bold_yellow Building a Influxdb database image...\n\n$reset"
	docker build -t 6_influxdb_database srcs/services/6_influxdb_database/ > 6_influxdb_database.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

#################### 7_grafana_influxdblinked ####################
	# A Grafana platform, listening on port 3000, linked with an InfluxDB database
	# Grafana will be monitoring all your containers.
	# You must create one dashboard per services
	edit_ip_variable 'grafana'
	echo -ne "$bold_green MINIKUBE_IP variable inside ./srcs/services/7_grafana_influxdblinked/grafana.ini file was replaced with the address $MINIKUBE_IP\n\n"

	echo -ne "$bold_yellow Building a Grafana web dashboard image...\n\n$reset"
	docker build -t 7_grafana_influxdblinked srcs/services/7_grafana_influxdblinked/ > 7_grafana_influxdblinked.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"

#################### 8_telegraf_influxdblinked ####################
	# Telegraf will collect metrics from a variety of different systems and
	# push to InfluxDB so they can be later analyzed in Grafana
	edit_ip_variable 'telegraf'
	echo -ne "$bold_green MINIKUBE_IP variable inside ./srcs/services/8_telegraf_influxdblinked/Dockerfile file was replaced with the address $MINIKUBE_IP\n\n"

	echo -ne "$bold_yellow Building a Telegraf image...\n\n$reset"
	docker build -t 8_telegraf_influxdblinked srcs/services/8_telegraf_influxdblinked/ > 8_telegraf_influxdblinked.txt

	echo -ne "$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"
}


#################### Create pods and services #####################
function create_pods_services()
{
	echo -ne "$bold_yellow Creating pods and services...\n\n$reset"

	SERVICES="1_nginx_server 2_ftps_server 3_mysql_database 4_wordpress_mysqllinked 5_phpmyadmin_mysqllinked 6_influxdb_database 8_telegraf_influxdblinked 7_grafana_influxdblinked"

	for service in $SERVICES
	do
		kubectl apply -f srcs/yaml_files/services_yaml/$service.yaml
		# kubectl apply -f will create a service using the definition in a yaml file
		echo ""
	done

	echo -ne "\n$bold_green Pods and services created!\n\n"
	echo -e "$bold_white ------------------------------------\n"
}


#################### Kubernetes web dashboard ####################
function kubernetes_dashboard()
{
	# Kubernetes dashboard is a web-based UI for Kubernetes clusters
	# This will help you manage your clusters
	echo -ne "$bold_yellow Starting Kubernetes web dashboard...\n\n$reset"
	# If Minikube was not being used, a more complex "installation" would have to be done
	# BUT as Minikube has integrated support for the Kubernetes Dashboard UI, just run:
	$1 minikube dashboard &
	# If you don’t want to open a web browser, the dashboard command can also simply
	# emit a URL: minikube dashboard --url
}


###############################################################################
############################## Script for MacOS ###############################
###############################################################################
if [[ $1 = 'mac' && $OSTYPE = 'darwin20' ]] ; then

############################ Minikube ############################
# Minikube is a tool that makes it easy to run Kubernetes locally
# This script will install it if it's not already installed
# Normaly Minikube is already installed on the 42 Mac


	#################### Check Virtualisation ####################
	# To check if virtualization is supported on MacOS, the following command
	# will verify if the output contains a colored VMX, therefor the VT-x
	# feature is enabled in your machine
	echo -ne "$bold_yellow Minikube - Checking if vizualisation is supported (only for 42 Mac)...\n\n"
	sysctl -a | grep -E --color 'machdep.cpu.features|VMX' &> /dev/null
	if [[ $? != 0 ]] ; then
		# it'll show how to enable the vizualisation
		echo -ne "$bold_red Please activate the virtualisation on your virtualbox Machine and restart the script.\n\n"
		echo -ne "$bold_dark_blue To enable virtualization in Ubuntu virtual machine:\n"
		echo -ne "$bold_cyan_filled 1. Turn on the System and F2 key at startup BIOS Setup\n"
		echo -ne "$bold_cyan_filled 2. Go to Advanced|CPU or Northbridge or Chipset menu\n"
		echo -ne "$bold_cyan_filled 3. Select VT Virtualization Technology or vmx and/or svm and then select Enabled.\n\n"
		exit
	elif [[ $? = 1 ]] ; then
		echo -ne "$bold_green Virtualisation is enabled!\n\n"
		echo -e "$bold_white ------------------------------------\n"
	fi


	###################### Install Minikube ######################
	function install_minikube()
	{
		echo -ne "$bold_red Minikube is not updated or installed.\n$bold_green Installing...$reset\n\n"
		sudo rm -rf /usr/local/bin/minikube
		curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
		# Make the minikube binary executable
		chmod +x ./minikube
		# Add the Minikube executable to your path
		sudo mv ./minikube /usr/local/bin/minikube
		echo -ne "\n$bold_green Minikube installed\n\n"
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


	################### Install Docker Desktop ###################
	# Won't do script for 42 Machines cause this project will be corected
	# either on the 42 VM Linux or on the peer MacOS if s/he has one
	echo -ne "$bold_yellow Checking if Docker Desktop is installed...\n\n"
	which docker > /dev/null
	if [[ $? == 0 ]] ; then
		echo -ne "$bold_green Docker Desktop is already installed!\n\n"
		echo -e "$bold_white ------------------------------------\n"
	else
		echo -ne "$bold_red Docker Desktop is not installed! Please install it and run setup.sh again.\n\n"
		echo -ne "$bold_dark_blue To install Docker Desktop for Mac: https://download.docker.com/mac/stable/Docker.dmg\n"
		echo -ne " Then follow these steps: https://docs.docker.com/docker-for-mac/install/#install-and-run-docker-desktop-on-mac\n"
		echo -ne "\n Obs: At 42 machine: Download Docker Desktop with MSC and select destination to goinfre.\n\n"
		echo -e "$bold_white ------------------------------------\n"
	fi


######################### Start Minikube #########################
	# Checking if  cluster is running, else, stop cluster
	echo -ne "$bold_yellow Starting Minikube cluster...\n\n$reset"
	minikube config set driver virtualbox &> /dev/null

	# if any cluster already exists, delete everything
	minikube status | grep -c "Running" > /dev/null
	if [[ $? == 0 ]] ; then
		echo -ne "$bold_yellow If any Minikube cluster is running, it will be deleted, together with it's virtualbox.\n\n"
		./setup.sh delete mac
	fi

	# For MacOS: launch minikube with virtualbox as the driver
	minikube start --vm-driver=virtualbox --cpus=2
	# This command <minikube start> creates and configures a Virtual Machine
	# that runs a single-node Kubernetes cluster. This command also configures
	# your kubectl installation to communicate with this cluster
	if [[ $? == 0 ]] ; then
		minikube addons enable metrics-server > /dev/null
		echo "🌟  The 'metrics-server' addon is enabled"
		minikube addons enable dashboard > /dev/null
		echo "🌟  The 'dashboard' addon is enabled"
		eval $(minikube docker-env)
		# The command minikube docker-env returns a set of Bash environment
		# variable exports to configure your local environment to re-use the
		# Docker daemon inside the Minikube instance.
		# eval: Execute arguments as a shell command
		# i.e., passing this output through eval causes bash to evaluate these
		# exports and put them into effect
		minikube status | grep -c "Running" > /dev/null
		# grep -c = print a count of matching lines containing the pattern
		if [[ $? == 0 ]] ; then
			config_cluster_ips
			echo -ne "$bold_green Minikube cluster started!\n\n"
			echo -e "$bold_white ------------------------------------\n"
		fi
	else
		minikube delete > /dev/null
		echo -ne "$bold_red Error: Minikube cluster NOT started :( Review script and re-start minikube with --alsologtostderr -v=7 to debug crashes\n\n"
		exit
	fi


##################### Load Balancer MetalLB ######################
	echo -ne "$bold_yellow Installing MetalLB LoadBalancer...\n\n$reset"
	# It will be the only entry point to your cluster,
	# which manages the external access of your services
	install_metallb
	# NO need to build a Docker image (from a Dockerfile) for the LoadBalancer
	# since it it's not a service pod inside a node, it's an entry point to the
	# Cluster that has the nodes with the pods inside
	echo -ne "\n$bold_green Done!\n\n"
	echo -e "$bold_white ------------------------------------\n"


############################ Services ############################
	build_docker_images
	create_pods_services

	echo -ne "\033[5;32m Minikube IP will open on your browser: http://$MINIKUBE_IP/\n\n$reset"
	open http://$MINIKUBE_IP

	export sudo=''
	kubernetes_dashboard $sudo


######################### Cheking OS #############################
elif [[ $1 = 'mac' && $OSTYPE = 'linux-gnu' ]] ; then
	echo -e "\n$bold_red You are not on a MacOS, you are on a VM Linux :/\n"
	exit
fi


###############################################################################
############################# Script for VM Linux #############################
###############################################################################
if [[ $1 = 'vm' && $OSTYPE = 'linux-gnu' ]] ; then


################## Update and install Packages ###################
	echo -ne "$bold_yellow Updating and installing packages (it may take some seconds)...\n\n"

	echo -ne "$bold_dark_blue Sudo privileges may be necessary to update and install Linux packages.\n"
	echo -ne " If requested, please type the ${bold_white}$(whoami) password ${bold_dark_blue}down below!\n \n$bold_white"
	sleep 3
	# Modifying the user account, adding the user whoami to the group sudo
	# Group is a list of supplementary groups which the user is also a member of
	sudo usermod -aG sudo $(whoami) > /dev/null

	sudo apt-get -y update > /dev/null
	sudo apt-get -y upgrade > /dev/null
	sudo apt-get -y install curl > /dev/null
	echo -e "$bold_green Done!\n"
	echo -e "$bold_white ------------------------------------\n"


########################### Minikube #############################
# Minikube is a tool that makes it easy to run Kubernetes locally
# This script will install it if it's not already installed
# Normaly Minikube is already installed on the 42 VM


	################### Check Virtualisation #####################
	# If flag --vm-driver=docker is used on VM, virtualization is not necessary


	##################### Install Minikube #######################
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
		# Manage Docker as a non-root user:
		# For some reason, by default, on 42's VM you can't run Docker without
		# sudo and Minikube will not work if that's the case. So let's fix that:
		sudo groupadd docker &> /dev/null
		sudo usermod -aG docker $(whoami) &> /dev/null
		# Configure Docker to start on boot:
		# systemctl command is basically a more powerful version of service (used on linux)
		sudo systemctl enable docker &> /dev/null
		sudo systemctl start docker
		echo -ne "\n$bold_green Docker installed!\n\n"
		echo -e "$bold_white ------------------------------------\n"
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
	elif [[ $WHICH_DOCKER != '/usr/bin/docker' ]] ; then
		echo -ne "\n$bold_red Docker is not installed!\n"
		install_docker
	else
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
		./setup.sh delete vm
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

	echo -ne "\033[5;32m Minikube IP will open on your browser: http://$MINIKUBE_IP/\n\n$reset"
	xdg-open http://$MINIKUBE_IP

	export sudo='sudo'
	kubernetes_dashboard $sudo


######################### Cheking OS #############################
elif [[ $1 = 'vm' && $OSTYPE = 'darwin20' ]] ; then
	echo -e "\n$bold_red You are not on a VM Linux, you are on a MacOS :/\n"
	exit
fi
