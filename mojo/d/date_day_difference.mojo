from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn date_floor_div(value:Int64,divisor:Int64)->Int64:
    var q=value/divisor
    let r=value%divisor
    if r!=0 and value<0:q-=1
    return q
fn date_leap(year:Int64)->Bool:
    return year%400==0 or (year%100!=0 and year%4==0)
fn date_ordinal(day:Int64,month:Int64,year:Int64)->Int64:
    var correction:Int64=0
    if month>2:
        if date_leap(year):correction=-1
        else:correction=-2
    let prior=year-1
    return 365*prior+date_floor_div(prior,4)-date_floor_div(prior,100)+date_floor_div(prior,400)+day+date_floor_div(367*month-362,12)+correction
fn date_parse(values:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,end:Int)->Int64:
    var pos=start;var day:Int64=0;var month:Int64=0;var year:Int64=0;var digits=0
    while pos<end and values[pos]>=48 and values[pos]<=57 and digits<3:
        day=day*10+values[pos]-48;digits+=1;pos+=1
    if digits<1 or digits>2 or pos>=end or values[pos]!=47:return -9223372036854775807
    pos+=1;digits=0
    while pos<end and values[pos]>=48 and values[pos]<=57 and digits<3:
        month=month*10+values[pos]-48;digits+=1;pos+=1
    if digits<1 or digits>2 or pos>=end or values[pos]!=47:return -9223372036854775807
    pos+=1
    if end-pos!=4:return -9223372036854775807
    while pos<end:
        if values[pos]<48 or values[pos]>57:return -9223372036854775807
        year=year*10+values[pos]-48;pos+=1
    if month<1 or month>12 or year<0 or year>9999 or day<1:return -9223372036854775807
    var maxday:Int64=31
    if month==2:
        maxday=28
        if date_leap(year):maxday=29
    elif month==4 or month==6 or month==9 or month==11:maxday=30
    if day>maxday:return -9223372036854775807
    return date_ordinal(day,month,year)

@export("date_day_difference")
fn date_day_difference(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<17 or length>21:return -1
    var separator=Int(length)
    for i in range(Int(length)):
        if values[i]==124:
            if separator!=Int(length):return -1
            separator=i
    if separator==Int(length):return -1
    let first=date_parse(values,0,separator)
    let second=date_parse(values,separator+1,Int(length))
    if first == -9223372036854775807 or second == -9223372036854775807:return -1
    if first>second:return first-second
    return second-first
