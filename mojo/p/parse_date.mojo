from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn pd_digits(v:UnsafePointer[Int64,ImmutAnyOrigin],a:Int,b:Int)->Int:
    var x=0
    for i in range(a,b):if v[i]<48 or v[i]>57:return -1;x=x*10+Int(v[i]-48)
    return x
@export("parse_date")
fn parse_date(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<9 or n>11 or v[0]<8 or v[0]>10 or Int(n)!=Int(v[0])+1:return -1
    let len=Int(v[0]);var slash1=0;var slash2=0
    for i in range(len):let x=v[i+1];if x<0 or x>127:return -1;if x==47:if slash1==0:slash1=i+1 elif slash2==0:slash2=i+1 else:return -1
    if slash1==0 or slash2==0 or slash2<=slash1+1 or len+1-slash2!=4 or slash1<2 or slash1>3 or slash2-slash1<2 or slash2-slash1>3:return -1
    let d=pd_digits(v,1,slash1);let m=pd_digits(v,slash1+1,slash2);let y=pd_digits(v,slash2+1,len+1)
    if d<0 or m<1 or m>12 or y<0:return -1
    var days=InlineArray[Int64,12](31,28,31,30,31,30,31,31,30,31,30,31)
    if m==2 and y%4==0 and (y%100!=0 or y%400==0):days[1]=29
    if d<1 or d>days[m-1]:return -1
    return Int64(y*10000+m*100+d)
