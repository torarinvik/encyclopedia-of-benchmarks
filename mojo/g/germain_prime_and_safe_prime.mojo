from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn gp_prime(n:Int64)->Bool:
    if n==2:return True
    if n<2 or n%2==0:return False
    var d:Int64=3
    while d<=n//d:
        if n%d==0:return False
        d+=2
    return True
@export("germain_prime_and_safe_prime")
fn germain_prime_and_safe_prime(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let x=v[0];let sel=v[1];if x<1 or x>1000000 or sel<0 or sel>1:return -1
    if sel==0:return 1 if gp_prime(x) and gp_prime(2*x+1) else 0
    return 1 if (x-1)%2==0 and gp_prime(x) and gp_prime((x-1)//2) else 0
