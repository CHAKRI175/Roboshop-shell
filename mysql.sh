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
dnf install mysql-server -y &>>$log_file
validate $? "mysql-server"

echo -e "$G MySQL installation completed successfully. $NC" | tee -a $log_file

systemctl enable mysqld | &>>$log_file
validate $? "mysql service enable "

systemctl start mysqld
validate $? "mysql service start"

mysql_secure_installation --set-root-pass RoboShop@1
validate $? "mysql secure installation"