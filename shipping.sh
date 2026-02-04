owner=$(id -u)
logs_dir="/var/log/RoboShop-shell"
log_file="$logs_dir/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
NC="\e[0m"
Path=$PWD   
MYSQL_HOST=mysql.chakri.sbs
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

dnf install maven -y
validate $? "maven"
echo -e "$G Maven installation completed successfully. $NC" | tee -a $log_file

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
validate $? "shipping zip download" 

cd /app
validate $? "change to app directory"

unzip /tmp/shipping.zip &>>$log_file
validate $? "shipping zip extract"

mvn clean package &>>$log_file
validate $? "maven build"

mv target/shipping-1.0.jar shipping.jar 
validate $? "maven build"   

cp $Path/shipping.service.repo /etc/systemd/system/shipping.service
validate $? "shipping service file copy"

systemctl daemon-reload &>>$log_file
validate $? "daemon reload"

systemctl enable shipping &>>$log_file
validate $? "shipping service enable"   

systemctl start shipping
validate $? "shipping service start"    

echo -e "$G Shipping service installation completed successfully. $NC" | tee -a $log_file

dnf install mysql -y &>>$log_file
validate $? "mysql client install"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then

    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$log_file
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$log_file
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$log_file
    validate $? "Loaded data into MySQL"
else
    echo -e "data is already loaded ... $Y SKIPPING $N"
fi

systemctl enable shipping &>>$log_file
systemctl start shipping
validate $? "Enabled and started shipping"



