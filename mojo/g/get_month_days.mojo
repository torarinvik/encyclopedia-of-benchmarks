@export("get_month_days")
fn get_month_days(month:Int64,year:Int64) abi("C")->Int64:
    if year<0 or year>9999:return -1
    if month==1 or month==3 or month==5 or month==7 or month==8 or month==10 or month==12:return 31
    if month==4 or month==6 or month==9 or month==11:return 30
    if month==2:return 29 if year%400==0 or (year%100!=0 and year%4==0) else 28
    return -1
