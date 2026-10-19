from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn dio_gcd(a0:Int64,b0:Int64)->Int64:
    var a=if a0<0:-a0 else:a0;var b=if b0<0:-b0 else:b0
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("linear_diophantine_eqn")
fn linear_diophantine_eqn(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3 or v[0]<-100000 or v[0]>100000 or v[1]==0 or v[1]<-100000 or v[1]>100000 or v[2]<-1000000 or v[2]>1000000:return -1
    return Int64(v[2]%dio_gcd(v[0],v[1])==0)
