from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer

fn date_is_digit(v:Int64)->Bool:return v>=48 and v<=57
fn date_field(input:UnsafePointer[Int64,ImmutAnyOrigin],end:Int,mut cursor:Int,min_digits:Int,max_digits:Int)->Int:
    let start=cursor;var value=0
    while cursor<end and date_is_digit(input[cursor]):value=value*10+Int(input[cursor]-48);cursor+=1
    let n=cursor-start
    if n<min_digits or n>max_digits:return -1
    return value
@export("date_to_day")
fn date_to_day(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<9 or length>11 or input[Int(length)-1]!=0:return -1
    let end=Int(length)-1;var cursor=0
    let day=date_field(input,end,cursor,1,2)
    if day<0 or cursor>=end or input[cursor]!=47:return -1
    cursor+=1;let month=date_field(input,end,cursor,1,2)
    if month<0 or cursor>=end or input[cursor]!=47:return -1
    cursor+=1;let year=date_field(input,end,cursor,4,4)
    if year<0 or cursor!=end or year<1 or year>9999 or month<1 or month>12 or day<1:return -1
    let leap=year%400==0 or (year%4==0 and year%100!=0)
    var maxday=31
    if month==2:
        maxday=28
        if leap:maxday=29
    elif month==4 or month==6 or month==9 or month==11:maxday=30
    if day>maxday:return -1
    var y=year;var m=month
    if m<3:y-=1;m+=12
    let century=y/100;let yy=y%100
    let weekday=(day+((m+1)*26)/10+yy+yy/4+century/4+5*century)%7
    var name="Saturday"
    if weekday==1:name="Sunday"
    elif weekday==2:name="Monday"
    elif weekday==3:name="Tuesday"
    elif weekday==4:name="Wednesday"
    elif weekday==5:name="Thursday"
    elif weekday==6:name="Friday"
    let size=len(name)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(size):return -2
    for i in range(size):output[i]=UInt8(name[i])
    return Int64(size)
