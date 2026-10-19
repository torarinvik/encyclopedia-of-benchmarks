from std.memory import MutAnyOrigin, UnsafePointer
@export("prime_factorization")
fn prime_factorization(n:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],cap:UInt64) abi("C")->Int64:
    if n<1 or n>1000005:return -1
    var rem=n;var primes=InlineArray[UInt32,10](fill=0);var exps=InlineArray[UInt32,10](fill=0);var count=0;var d=Int64(2)
    while d<=rem//d:
        if rem%d==0:
            var e=UInt32(0)
            while rem%d==0:rem//=d;e+=1
            primes[count]=UInt32(d);exps[count]=e;count+=1
        d+=1
    if rem>1:primes[count]=UInt32(rem);exps[count]=1;count+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<UInt64(count*8):return -2
    for i in range(count):for b in range(4):out[i*8+b]=UInt8((primes[i]>>(8*b))&255);out[i*8+4+b]=UInt8((exps[i]>>(8*b))&255)
    return Int64(count*8)
