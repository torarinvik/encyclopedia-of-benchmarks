from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("modular_multiplicative_inverse")
fn modular_multiplicative_inverse(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let a=v[0];let m=v[1]
    if m<2 or m>1000000 or a<0 or a>=m:return -1
    var oldr=a;var r=m;var olds:Int64=1;var s:Int64=0
    while r!=0:
        let q=oldr/r;let nr=oldr-q*r;let ns=olds-q*s;oldr=r;r=nr;olds=s;s=ns
    if oldr!=1:return -1
    let x=olds%m;return x+m if x<0 else x
