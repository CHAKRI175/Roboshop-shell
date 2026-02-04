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
        echo -e "$2 $R ...... failed. $NC" | tee -a $log_file
        exit 1
    else
        echo -e "$2 $G ...... successful. $NC" | tee -a $log_file
    fi
}   

dnf module disable nodejs -y
validate $? "nodejs module disable"

dnf module enable nodejs:20 -y
validate $? "nodejs module enable"

dnf install nodejs -y &>>$log_file
validate $? "nodejs installation"

echo -e "$G Nodejs installation completed successfully. $NC" | tee -a $log_file

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
validate $? "roboshop user add"

else
    echo -e "$Y roboshop user already exists. $NC" | tee -a $log_file
fi  

mkdir -p /app
validate $? "app directory creation"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
validate $? "catalogue zip download"

cd /app
validate $? "change to app directory"

rm -rf /app/*
validate $? "clean app directory"

unzip /tmp/catalogue.zip &>>$log_file
validate $? "catalogue zip extract"

npm install &>>$log_file
validate $? "npm dependencies installation"

cp $Path/catalogue.service /etc/systemd/system/catalogue.service
validate $? "catalogue service file copy"

systemctl daemon-reload
validate $? "systemd daemon reload"

systemctl enable catalogue | &>>$log_file
validate $? "catalogue service enable "

systemctl start catalogue
validate $? "catalogue service start"   

echo -e "$G Catalogue service setup completed successfully. $NC" | tee -a $log_file

cp $Path/mongodb.repo /etc/yum.repos.d/mongo.repo
validate $? "mongodb repo file copy"

dnf install mongodb-org-shell -y &>>$log_file
validate $? "mongodb-org-shell installation"

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -eq -1 ]; then
    mongosh --host $MONGODB_HOST --quiet  < $Path/catalogue.js &>>$log_file
    validate $? "catalogue schema setup"
else
    echo -e "$Y catalogue schema is already present. $NC" | tee -a $log_file
fi
echo -e "$G Catalogue schema setup completed successfully. $NC" | tee -a $log_file

systemctl restart catalogue
validate $? "catalogue service restart"

echo -e "$G Catalogue service restarted successfully. $NC" | tee -a $log_file
