$date = (get-date).dayofyear
get-service | out-file "C:\Users\Bob\Desktop\$date.txt"