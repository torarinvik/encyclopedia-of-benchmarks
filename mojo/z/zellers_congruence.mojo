from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("zellers_congruence")
fn zellers_congruence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    var y=v[0];var m=v[1];let d=v[2]
    if y<46 or y>8499 or m<1 or m>12 or d<1:return -1
    var days=InlineArray[Int,12](fill=0);days[0]=31;days[1]=28;days[2]=31;days[3]=30;days[4]=31;days[5]=30;days[6]=31;days[7]=31;days[8]=30;days[9]=31;days[10]=30;days[11]=31
    let leap=y%4==0 and (y%100!=0 or y%400==0)
    var maxday=days[Int(m)-1];if m==2 and leap:maxday+=1
    if d>maxday:return -1
    if m<=2:y-=1;m+=12
    let century=y/100;let yc=y%100;let term=(260*m-539)/100
    let total=d+yc+term+century/4+yc/4-2*century
    var w=total%7;if w<0:w+=7
    return w
