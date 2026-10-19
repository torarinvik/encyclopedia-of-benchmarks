from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mh_gcd(mut a:UInt64,mut b:UInt64)->UInt64:
    while b!=0:let r=a%b;a=b;b=r
    return a
fn mh_add(a:UInt64,b:UInt64,m:UInt64)->UInt64:
    return a-(m-b) if a>=m-b else a+b
fn mh_mul(mut a:UInt64,mut b:UInt64,m:UInt64)->UInt64:
    var res:UInt64=0;a%=m
    while b!=0:
        if b&1!=0:res=mh_add(res,a,m)
        b>>=1
        if b!=0:a=mh_add(a,a,m)
    return res
fn mh_inv(value:UInt64,m:UInt64)->UInt64:
    var orr=m;var r=value%m;var ot:UInt64=0;var t:UInt64=1
    while r!=0:
        let q=orr/r;let nr=orr%r;let product=mh_mul(q%m,t,m)
        let nt=if ot>=product:ot-product else:m-(product-ot)
        orr=r;r=nr;ot=t;t=nt
    return ot
fn mh_store(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[p+b]=UInt8((u>>(8*b))&255)
@export("merkle_hellman_cryptosystem")
fn merkle_hellman_cryptosystem(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<12 or n>43:return -1
    if v[0]<0 or v[0]>127 or v[10]<1 or v[10]>32 or Int(n)!=11+Int(v[10]):return -1
    let draws=Int(v[10]);var easy=InlineArray[UInt64,8](fill=0);var sum:UInt64=UInt64(1)<<32
    for i in range(8):
        if v[1+i]<0 or v[1+i]>4294967295:return -1
        easy[i]=sum+UInt64(v[1+i]);sum+=easy[i]
    if v[9]<0 or v[9]>4294967295:return -1
    let modulus=sum+UInt64(v[9])
    for i in range(draws):
        let d=v[11+i]
        if d<0 or UInt64(d)>modulus:return -1
        let g=mh_gcd(UInt64(d),modulus)
        if i+1<draws and g==1:return -1
        if i+1==draws and g!=1:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<17:return -2
    let mult=UInt64(v[10+draws]);var hard=InlineArray[UInt64,8](fill=0)
    for i in range(8):hard[i]=mh_mul(mult,easy[i],modulus)
    var cipher:UInt64=0;let message=UInt64(v[0])
    for bit in range(8):if (message>>UInt64(7-bit))&1!=0:cipher+=hard[bit]
    let inv=mh_inv(mult,modulus);var residue=mh_mul(inv,cipher%modulus,modulus);var decoded:UInt64=0
    for i in range(8):
        let w=easy[7-i]
        if residue>=w:residue-=w;decoded|=UInt64(1)<<UInt64(i)
    if residue!=0 or decoded!=message:return -1
    mh_store(out,0,Int64(cipher));mh_store(out,8,1);out[16]=UInt8(decoded);return 17
