owner=(id -u)
logs_dir=/tmp/roboshop/logs
log_file=$logs_dir/$0.log
R='\e[31m'
G='\e[32m'
Y='\e[33m'
B='\e[34m'
NC='\e[0m'
Path=$PWD
if [ $owner -ne 0 ]; then
    echo -e "$R Please run this script as root. $NC" | tee -a $log_file
    exit 1
fi
mkdir -p $logs_dir
validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 $R .....installation failed. $NC" | tee -a $log_file
        exit 1
    else
        echo -e "$2 $G .....installation successful. $NC" | tee -a $log_file
    fi
}   

dnf install python3 gcc python3-devel -y
validate $? "python3 and gcc installation"

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

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$log_file
validate $? "payment zip download"

cd /app
validate $? "change to app directory"

unzip /tmp/payment.zip &>>$log_file
validate $? "payment zip extract"

pip3 install -r requirements.txt &>>$log_file
validate $? "python dependencies installation"

cp $Path/payment.service.repo /etc/systemd/system/payment.service
validate $? "payment service file copy"

systemctl daemon-reload &>>$log_file
validate $? "daemon reload"

systemctl enable payment &>>$log_file
validate $? "payment enable"    

systemctl start payment &>>$log_file
validate $? "payment start" 

echo -e "$G Payment service setup completed successfully. $NC" | tee -a $log_file   


