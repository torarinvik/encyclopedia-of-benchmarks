from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kaprekar_constant")
fn kaprekar_constant(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    var x=a[0];let limit=a[1]
    if x<0 or x>9999 or limit<1 or limit>16:return -1
    if x==6174:return 0
    for step in range(1,Int(limit)+1):
        var d0=x//1000;var d1=(x//100)%10;var d2=(x//10)%10;var d3=x%10;var t:Int64=0
        if d0>d1:t=d0;d0=d1;d1=t
        if d2>d3:t=d2;d2=d3;d3=t
        if d0>d2:t=d0;d0=d2;d2=t
        if d1>d3:t=d1;d1=d3;d3=t
        if d1>d2:t=d1;d1=d2;d2=t
        x=(d3*1000+d2*100+d1*10+d0)-(d0*1000+d1*100+d2*10+d3)
        if x==6174:return step
        if x==0:return -1
    return -1
