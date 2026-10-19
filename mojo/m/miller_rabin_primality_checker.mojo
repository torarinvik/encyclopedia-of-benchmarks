from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn mrpc_next(mut state:UInt64)->UInt64:
    state+=UInt64(0x9e3779b97f4a7c15);var z=state
    z=(z^(z>>30))*UInt64(0xbf58476d1ce4e5b9);z=(z^(z>>27))*UInt64(0x94d049bb133111eb)
    return z^(z>>31)
fn mrpc_pow(mut b:Int64,mut e:Int64,n:Int64)->Int64:
    var r:Int64=1
    while e>0:
        if e&1!=0:r=(r*b)%n
        b=(b*b)%n;e>>=1
    return r
fn mrpc_pass(n:Int64,a:Int64,d:Int64,s:Int)->Bool:
    var x=mrpc_pow(a,d,n)
    if x==1 or x==n-1:return True
    for _ in range(1,s):x=(x*x)%n;if x==n-1:return True
    return False
@export("miller_rabin_primality_checker")
fn miller_rabin_primality_checker(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>4:return -1
    let x=v[0];let rounds=v[1];let seed=v[2]
    if n!=3 or x<5 or x>2147483647 or x%2==0 or rounds<1 or rounds>64 or seed<0 or seed>2147483647:return -1
    var state=UInt64(seed);let span=UInt64(x-4);let threshold=(UInt64(0)-span)%span;var word=mrpc_next(mut state)
    while word<threshold:word=mrpc_next(mut state)
    let witness=2+Int64(word%span);var d=x-1;var s=0
    while d&1==0:d>>=1;s+=1
    for _ in range(Int(rounds)):if not mrpc_pass(x,witness,d,s):return 0
    return 1
