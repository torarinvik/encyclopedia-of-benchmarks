from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn mbe_rec(a:Int64,e:Int64,m:Int64)->Int64:
    if e==0:return 1
    if e&1!=0:return (mbe_rec(a,e-1,m)*a)%m
    let h=mbe_rec(a,e//2,m);return (h*h)%m
@export("modular_binary_exponentiation_recursive")
fn modular_binary_exponentiation_recursive(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let a=v[0];let e=v[1];let m=v[2]
    if a<0 or a>1000000 or e<0 or e>60 or m<2 or m>1000000:return -1
    return mbe_rec(a,e,m)
