from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn dsa_prime(n:Int64)->Bool:
    if n<2:return false
    var d:Int64=2
    while d*d<=n:
        if n%d==0:return false
        d+=1
    return true
fn dsa_pow(base0:Int64,exp0:Int64,modulus:Int64)->Int64:
    var base=base0%modulus;var exp=exp0;var result:Int64=1
    while exp>0:
        if (exp&1)!=0:result=result*base%modulus
        base=base*base%modulus;exp>>=1
    return result
@export("dsa_verify")
fn dsa_verify(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<7 or length>15:return -1
    let p=input[0];let q=input[1];let g=input[2];let y=input[3];let r=input[4];let s=input[5];let ml=input[6]
    if ml<0 or ml>8 or length!=c_size_t(7+ml):return -1
    if p<5 or p>251 or not dsa_prime(p) or q<2 or q>=p or (p-1)%q!=0 or not dsa_prime(q):return -1
    if g<2 or g>=p or dsa_pow(g,q,p)!=1 or y<1 or y>=p or dsa_pow(y,q,p)!=1 or r<1 or r>=q or s<1 or s>=q:return -1
    var h:Int64=0
    for i in range(Int(ml)):
        let b=input[7+i]
        if b<0 or b>255:return -1
        h=(h*256+b)%q
    let w=dsa_pow(s,q-2,q);let u1=h*w%q;let u2=r*w%q
    return 1 if (dsa_pow(g,u1,p)*dsa_pow(y,u2,p)%p)%q==r else 0
