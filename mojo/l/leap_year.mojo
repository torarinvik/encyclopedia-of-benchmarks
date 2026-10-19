@export("leap_year")
fn leap_year(year:Int64) abi("C")->Int64:
    if year<=0:return -1
    return Int64(year%400==0 or (year%4==0 and year%100!=0))
