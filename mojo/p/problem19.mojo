fn p19_leap(year:Int)->Bool:
    return year%400==0 or (year%4==0 and year%100!=0)
@export("problem19")
fn problem19(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var weekday=2;var count=Int64(0)
    for year in range(1901,2001):
        for month in range(1,13):
            if weekday==0:count+=1
            var days=31
            if month==4 or month==6 or month==9 or month==11:days=30
            if month==2:days=29 if p19_leap(year) else 28
            weekday=(weekday+days)%7
    return count
