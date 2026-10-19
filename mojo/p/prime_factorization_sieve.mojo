from std.memory import MutAnyOrigin, UnsafePointer
@export("prime_factorization_sieve")
fn prime_factorization_sieve(n:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],cap:UInt64) abi("C")->Int64:
    if n<1 or n>1000005:return -1
    if n==1:return 0
    var sieve=InlineArray[Bool,1000006](fill=True);sieve[0]=False;sieve[1]=False;let limit=Int(n)
    for p in range(2,limit+1):
        if p>limit//p:break
        if not sieve[p]:continue
        for j in range(p*p,limit+1,p):sieve[j]=False
    var rem=n;var primes=InlineArray[UInt32,10](fill=0);var exps=InlineArray[UInt32,10](fill=0);var count=0
    for p in range(2,limit+1):
        if rem<=1:break
        if not sieve[p]:continue
        var e=UInt32(0)
        while rem%Int64(p)==0:rem//=Int64(p);e+=1
        if e>0:primes[count]=UInt32(p);exps[count]=e;count+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<UInt64(count*8):return -2
    for i in range(count):for b in range(4):out[i*8+b]=UInt8((primes[i]>>(8*b))&255);out[i*8+4+b]=UInt8((exps[i]>>(8*b))&255)
    return Int64(count*8)
