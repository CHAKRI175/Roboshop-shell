owner=$(id -u)
logs_dir="/var/log/RoboShop-shell" 
log_file="$logs_dir/$0.log"
R="\e[31m"
G="\e[32m"      
Y="\e[33m"
B="\e[34m"
NC="\e[0m"
Path=$PWD
if [ $owner -ne 0 ]; then
    echo -e "$R Please run this script as root. $NC" | tee -a $log_file
    exit 1
fi          
 
mkdir -p $logs_dir

validate(){ 
    if [ $1 -ne 0 ]; then
        echo -e "$2 $R installation failed. $NC" | tee -a $log_file
        exit 1
    else
        echo -e "$2 $G installation successful. $NC" | tee -a $log_file
    fi
}

dnf module disable redis -y &>>$log_file
dnf module enable redis:7 -y &>>$log_file
validate $? "redis module enable"

dnf install redis -y &>>$log_file
validate $? "redis-server"

echo -e "$G Redis installation completed successfully. $NC" | &>>$log_file

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
validate $? "redis config file change"

systemctl enable redis | &>>$log_file
validate $? "redis service enable "

systemctl start redis
validate $? "redis service start"



