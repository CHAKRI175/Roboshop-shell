owner=($(id -u))
logs_dir="/var/log/shell-practice.sh" 
log_file="/var/log/shell-practice/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
NC="\e[0m"
Path=$PWD
if [ $owner -ne 0 ]; then
    echo "$R Please run this script as root. $NC" | tee -a $log_file
    exit 1
fi

mkdir -p $logs_dir
validate(){

    if [ $1 -ne 0 ]; then
        echo "$2 $R installation failed. $NC" | tee -a $log_file
        exit 1
    else
        echo "$2 $G installation successful. $NC" | tee -a $log_file
    fi
}
cp mongodb.repo /etc/yum.repos.d/mongo.repo
validate $? "mongodb repo file copy"

dnf install mongodb-org -y | tee -a $log_file
validate $? "mongodb-server"

systemctl enable mongod 
validate $? "mongodb service enable and start"

systemctl status mongod | tee -a $log_file
validate $? "mongodb service status check"

systemctl start mongod
validate $? "mongodb service start"

echo -e "$G MongoDB installation and setup completed successfully. $NC" | tee -a $log_file

sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod    
validate $? "mongodb service restart after config change"