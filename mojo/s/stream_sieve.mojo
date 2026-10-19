from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("stream_sieve")
fn stream_sieve(n:Int64,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t)->Int64:
    if n< -2147483648 or n>100:return -1
    if n<=0:return 0
    let count=Int(n);let bytes=count*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var primes=InlineArray[Int32,100](fill=0);var pc=0;var cand=3
    if count>0:primes[0]=2;pc=1
    while pc<count:
        var prime=True
        for j in range(pc):
            let d=Int(primes[j]);if d>cand/d:break
            if cand%d==0:prime=False;break
        if prime:primes[pc]=Int32(cand);pc+=1
        cand+=1
    for i in range(count):let bits=bitcast[UInt32](primes[i]);for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
