from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn long_div_core(a0:Int64,b0:Int64)->Int64:
    if b0==0:return 0
    let neg=(a0<0)!=(b0<0);var a=if a0<0:-a0 else:a0;let b=if b0<0:-b0 else:b0
    var digits=InlineArray[Int64,16](fill=0);var count=0
    if a==0:digits[count]=0;count+=1
    while a!=0:digits[count]=a%10;count+=1;a/=10
    var rem:Int64=0;var q:Int64=0
    for k in range(count):
        let digit=digits[count-1-k];rem=rem*10+digit;var d:Int64=0
        while rem>=b:rem-=b;d+=1
        q=q*10+d
    return if neg:-q else:q
@export("long_division")
fn long_division(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0] < -1000000 or v[0]>1000000 or v[1] < -10000 or v[1]>10000:return -1
    return long_div_core(v[0],v[1])
