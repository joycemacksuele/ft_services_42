#!/bin/sh

SERVICE_LIST="ftps nginx wordpress phpmyadmin mysql grafana influxdb telegraf"

if [ $# -lt 1 ]
then
	echo "\nGive as argument the ip address of the cluster\n"
	exit
fi

echo "\n- Checking if services exist and have the correct name:"
for SERVICE in $SERVICE_LIST
do
	kubectl get pods | grep $SERVICE- 2>&1 > /dev/null
	if [ $? -ne 0 ]
	then
		echo "\033[31mERROR: service $SERVICE is missing or was not named correctly\033[0m"	
		exit
	else
		echo "\033[32m $SERVICE  ✅\033[m"
	fi
done

sleep 3
echo "\n- Checking if pods are running:"
for SERVICE in $SERVICE_LIST
do
	RUNNING=`kubectl get pods | grep $SERVICE | tr -s ' ' | cut -d ' ' -f 3`
	if [ "$RUNNING" = "Running" ]
	then
		echo "\033[32m $SERVICE is running\033[m"
	else
		echo "\033[31mERROR: $SERVICE is not running\033[m"
		exit
	fi
done

sleep 3
echo "\n- Checking if services have been restarted:"
for SERVICE in $SERVICE_LIST
do
	RESTARTS=`kubectl get pods | grep $SERVICE | tr -s ' ' | cut -d ' ' -f 4`
	if [ $RESTARTS -eq 0 ]
	then
		echo "\033[32m $SERVICE: 0 RESTARTS\033[m"
	else
		echo "\033[33m $SERVICE restarted $RESTARTS time(s)\033[m"
	fi
	done

sleep 3
echo "\n- Killing all the processes:"
for SERVICE in $SERVICE_LIST
do
	POD_NAME=`kubectl get pods | grep $SERVICE | cut -d ' ' -f 1`
	case $SERVICE in
		nginx)
		kubectl exec $POD_NAME -- pkill sshd 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m SSH killed\033[m"
		else
			echo "\033[31m SSH not killed\033[m"
		fi
		sleep 5
		kubectl exec $POD_NAME -- pkill nginx 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m $SERVICE killed\033[m"
		else
			echo "\033[31m $SERVICE not killed\033[m"
		fi
		;;
		telegraf)
		kubectl exec $POD_NAME -- pkill telegraf 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m $SERVICE killed\033[m"
		else
			echo "\033[31m $SERVICE not killed\033[m"
		fi
		;;
		ftps)
		kubectl exec $POD_NAME -- pkill vsftpd 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m $SERVICE killed\033[m"
		else
			echo "\033[31m $SERVICE not killed\033[m"
		fi
		;;
		mysql)
		kubectl exec $POD_NAME -- pkill mysqld 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m $SERVICE killed\033[m"
		else
			echo "\033[31m $SERVICE not killed\033[m"
		fi
		;;
		influxdb)
		kubectl exec $POD_NAME -- pkill influxd 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m $SERVICE killed\033[m"
		else
			echo "\033[31m $SERVICE not killed\033[m"
		fi
		;;
		grafana)
		kubectl exec $POD_NAME -- pkill grafana 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m $SERVICE killed\033[m"
		else
			echo "\033[31m $SERVICE not killed\033[m"
		fi
		;;
		wordpress)
		kubectl exec $POD_NAME -- pkill php-fpm 2>&1 > /dev/null
		sleep 5
		kubectl exec $POD_NAME -- pkill nginx 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m $SERVICE killed\033[m"
		else
			echo "\033[31m $SERVICE not killed\033[m"
		fi
		;;
		phpmyadmin)
		kubectl exec $POD_NAME -- pkill php-fpm 2>&1 > /dev/null
		sleep 5
		kubectl exec $POD_NAME -- pkill nginx 2>&1 > /dev/null
		if [ $? -ne 1 ]
		then
			echo "\033[32m $SERVICE killed\033[m"
		else
			echo "\033[31m $SERVICE not killed\033[m"
		fi
		;;
		*)
		;;
	esac
done
sleep 10
echo "\n5) Check in another terminal if there are any pods that can't restart:"
echo -n "\nCommand:\033[32m kubectl get pods \033[0m\n"
