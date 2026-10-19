from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn doomsday_leap(y:Int64)->Bool:return y%400==0 or (y%4==0 and y%100!=0)
fn doomsday_anchor(month:Int64,leap:Bool)->Int64:
    if month==1:return 4 if leap else 3
    if month==2:return 1 if leap else 7
    if month==3:return 7
    if month==4:return 4
    if month==5:return 2
    if month==6:return 6
    if month==7:return 4
    if month==8:return 1
    if month==9:return 5
    if month==10:return 3
    if month==11:return 7
    return 5
@export("doomsday")
fn doomsday(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1
    let year=input[0];let month=input[1];let day=input[2]
    if year<100 or year>9999 or month<1 or month>12:return -1
    let leap=doomsday_leap(year);var monthdays:Int64=31
    if month==2:monthdays=28 if not leap else 29
    elif month==4 or month==6 or month==9 or month==11:monthdays=30
    if day<1 or day>monthdays:return -1
    let century_anchor=(5*((year/100)%4)+2)%7;let within=year%100
    let doom=(within/12+within%12+(within%12)/4+century_anchor)%7
    var weekday=(doom+day-doomsday_anchor(month,leap))%7
    if weekday<0:weekday+=7
    return weekday
