from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gpb_prime(n:Int)->Bool:
    if n<2:return False
    var d=2
    while d<=n//d:
        if n%d==0:return False
        d+=1
    return True
fn gpb_digits(n:Int)->Int:
    if n>=100:return 3
    if n>=10:return 2
    return 1
fn gpb_write(out:UnsafePointer[UInt8,MutAnyOrigin],pos0:Int,x0:Int)->Int:
    var pos=pos0;var x=x0
    if x>=100:out[pos]=UInt8(48+x//100);pos+=1;x%=100
    if x>=10:out[pos]=UInt8(48+x//10);pos+=1;x%=10
    out[pos]=UInt8(48+x);return pos+1
@export("get_primes_between")
fn get_primes_between(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let p1=Int(v[0]);let p2=Int(v[1]);if p1<2 or p1>997 or p2<2 or p2>997 or p1>=p2 or not gpb_prime(p1) or not gpb_prime(p2):return -1
    var primes=InlineArray[Int,256](fill=0);var count=0
    for x in range(p1+1,p2):if gpb_prime(x):primes[count]=x;count+=1
    if count==0:return -1
    var needed=count-1
    for i in range(count):needed+=gpb_digits(primes[i])
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    var pos=0
    for i in range(count):
        if i>0:out[pos]=UInt8(44);pos+=1
        pos=gpb_write(out,pos,primes[i])
    return Int64(pos)
