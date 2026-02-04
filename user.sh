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

dnf module disable nodejs -y
dnf module enable nodejs:20 -y
validate $? "nodejs module enable"

dnf install nodejs -y &>>$log_file
validate $? "nodejs"

echo -e "$G NodeJS installation completed successfully. $NC" | tee -a $log_file

id -u roboshop &>>$log_file

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "roboshop user add"
else
    echo -e "$Y roboshop user already exists. $NC" | tee -a $log_file
fi  

mkdir -p /app
validate $? "app directory creation"

rm -rf /app/*
validate $? "clean app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$log_file
validate $? "user zip download"

cd /app
validate $? "change to app directory"

unzip /tmp/user.zip &>>$log_file
validate $? "user zip extract"

npm install &>>$log_file
validate $? "npm install"

cp $Path/user.service.repo /etc/systemd/system/user.service
validate $? "user service file copy"

systemctl daemon-reload &>>$log_file
validate $? "systemd daemon reload"

systemctl enable user | &>>$log_file
validate $? "user service enable "

systemctl start user
validate $? "user service start"
