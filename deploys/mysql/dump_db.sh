
mysqldump -h 127.0.0.1 -P 3306 -u root -p --single-transaction --skip-add-drop-table --databases db1 db2 > "db_backup_$(date +'%Y%m%d%H%M%S').sql"



