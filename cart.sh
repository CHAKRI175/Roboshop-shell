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
else
    echo -e "$Y roboshop user already exists. $NC" | tee -a $log_file
fi
validate $? "roboshop user add"

mkdir -p /app
validate $? "app directory creation"

rm -rf /app/*
validate $? "clean app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$log_file
validate $? "cart zip download"

cd /app
validate $? "change to app directory"   

unzip /tmp/cart.zip &>>$log_file
validate $? "cart zip extract"  

npm install &>>$log_file
validate $? "npm install"

cp $Path/cart.service.repo /etc/systemd/system/cart.service
validate $? "cart service file copy"    

systemctl daemon-reload &>>$log_file
validate $? "daemon reload"

systemctl enable cart &>>$log_file
validate $? "cart service enable"   

systemctl start cart
validate $? "cart service start"