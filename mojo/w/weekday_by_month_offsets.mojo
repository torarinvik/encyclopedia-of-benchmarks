from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("weekday_by_month_offsets")
fn weekday_by_month_offsets(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let y0=a[0];let m=a[1];let d=a[2]
    if y0<100 or y0>9999 or m<1 or m>12 or d<1:return -1
    var ml=InlineArray[Int64,12]();ml[0]=31;ml[1]=28;ml[2]=31;ml[3]=30;ml[4]=31;ml[5]=30;ml[6]=31;ml[7]=31;ml[8]=30;ml[9]=31;ml[10]=30;ml[11]=31
    let leap=(y0%4==0 and y0%100!=0) or y0%400==0
    if leap:ml[1]=29
    if d>ml[Int(m-1)]:return -1
    var y=y0;if m<3:y-=1
    var offsets=InlineArray[Int64,12]();offsets[0]=0;offsets[1]=3;offsets[2]=2;offsets[3]=5;offsets[4]=0;offsets[5]=3;offsets[6]=5;offsets[7]=1;offsets[8]=4;offsets[9]=6;offsets[10]=2;offsets[11]=4
    var w=(y+y/4-y/100+y/400+offsets[Int(m-1)]+d)%7
    if w<0:w+=7
    return w
