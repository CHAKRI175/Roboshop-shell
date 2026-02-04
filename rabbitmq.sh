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
cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$log_file

dnf install rabbitmq-server -y &>>$log_file
validate $? "rabbitmq-server"

systemctl enable rabbitmq-server &>>$log_file
validate $? "rabbitmq service enable "

systemctl start rabbitmq-server &>>$log_file
validate $? "rabbitmq service start"

echo -e "$G RabbitMQ installation completed successfully. $NC" | tee -a $log_file

rabbitmqctl add_user roboshop roboshop123
validate $? "rabbitmq user add"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "rabbitmq user permission set"
