from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn rsa_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let r=a%b;a=b;b=r
    return if a<0: -a else:a
fn rsa_pow(base:Int64,ex:Int64,m:Int64)->Int64:
    var power=base%m;var e=ex;var result:Int64=1
    while e>0:if e&1!=0:result=result*power%m;power=power*power%m;e/=2
    return result
fn next_rsa_draw(v:UnsafePointer[Int64,ImmutAnyOrigin],count:Int,mut cursor:Int,low:Int64,high:Int64)->Int64:
    if cursor>=count:return -1
    let x=v[cursor];cursor+=1
    if x<low or x>=high:return -1
    return x
fn rsa_prime(v:UnsafePointer[Int64,ImmutAnyOrigin],count:Int,mut cursor:Int,num:Int64)->Int:
    if num<2:return 0
    if num<=997:
        var d:Int64=2
        while d*d<=num:if num%d==0:return 0;d+=1
        return 1
    for d in range(2,998):if num%Int64(d)==0:return 0
    var s=num-1;var t=0
    while s%2==0:s/=2;t+=1
    for _ in range(5):
        let a=next_rsa_draw(v,count,cursor,2,num-1);if a<0:return -1
        var value=rsa_pow(a,s,num)
        if value!=1:
            var i=0
            while value!=num-1:
                if i==t-1:return 0
                i+=1;value=value*value%num
    return 1
fn rsa_hash_i64(mut h:UInt64,value:Int64)->UInt64:
    let bits=bitcast[UInt64](value)
    for j in range(8):h=(h^((bits>>(8*j))&UInt64(255)))*UInt64(1099511628211)
    return h
fn rsa_inverse(a:Int64,m:Int64)->Int64:
    if rsa_gcd(a,m)!=1:return -1
    var u1:Int64=1;var u2:Int64=0;var u3=a;var v1:Int64=0;var v2:Int64=1;var v3=m
    while v3!=0:
        let q=u3/v3;let nv1=u1-q*v1;let nv2=u2-q*v2;let nv3=u3-q*v3
        u1=v1;u2=v2;u3=v3;v1=nv1;v2=nv2;v3=nv3
    return u1%m
@export("generate_key")
fn rsa_key_generator(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1027:return -1
    let bits=v[0];let draws=v[1]
    if bits<2 or bits>20 or draws<0 or draws>1024 or Int(n)!=2+Int(draws):return -1
    let limit=Int64(1)<<Int(bits)
    for i in range(Int(draws)):if v[2+i]<2 or v[2+i]>=limit:return -1
    var cursor=0;let low=Int64(1)<<Int(bits-1);let high=limit
    var p:Int64=0;var q:Int64=0
    for which in range(2):
        var found=False
        while cursor<Int(draws):
            let candidate=next_rsa_draw(v,Int(draws),cursor,low,high);if candidate<0:return -1
            let prime=rsa_prime(v,Int(draws),cursor,candidate);if prime<0:return -1
            if prime==1:
                if which==0:p=candidate else:q=candidate
                found=True;break
        if not found:return -1
    let modulus=p*q;let phi=(p-1)*(q-1);var exponent:Int64=0;var founde=False
    while cursor<Int(draws):
        let candidate=next_rsa_draw(v,Int(draws),cursor,low,high);if candidate<0:return -1
        if rsa_gcd(candidate,phi)==1:exponent=candidate;founde=True;break
    if not founde:return -1
    let private=rsa_inverse(exponent,phi);if private<0:return -1
    var h=UInt64(14695981039346656037);h=rsa_hash_i64(h,modulus);h=rsa_hash_i64(h,exponent);h=rsa_hash_i64(h,modulus);h=rsa_hash_i64(h,private)
    return Int64(h&UInt64(0x7fffffffffffffff))
