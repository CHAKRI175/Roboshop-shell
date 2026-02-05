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

dnf module disable nginx -y
dnf module enable nginx:1.24 -y
validate $? "nginx module enable"

dnf install nginx -y
validate $? "nginx installation"

systemctl enable nginx 
systemctl start nginx 
validate $? "nginx start"

rm -rf /usr/share/nginx/html/*
validate $? "nginx html cleanup"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
validate $? "frontend zip download"

cd /usr/share/nginx/html
validate $? "change to nginx html directory"

unzip /tmp/frontend.zip &>>$log_file
validate $? "frontend zip extract"

cp $Path/frontend.repo /etc/nginx/nginx.conf
validate $? "nginx config copy"1

systemctl restart nginx
validate $? "nginx restart" 

echo -e "$G Frontend setup completed successfully. $NC" | tee -a $log_file