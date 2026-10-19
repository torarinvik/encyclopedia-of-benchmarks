from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("totients_linear_sieve")
fn totients_linear_sieve(n:Int64,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n<1 or n>80:return -1
    var phi=InlineArray[Int,81]();var composite=InlineArray[Bool,81]();var primes=InlineArray[Int,80]();var pc=0;phi[1]=1
    for i in range(2,Int(n)+1):
        if not composite[i]:primes[pc]=i;pc+=1;phi[i]=i-1
        for j in range(pc):
            let p=primes[j]
            if i*p>Int(n):break
            composite[i*p]=True
            if i%p==0:phi[i*p]=phi[i]*p;break
            phi[i*p]=phi[i]*(p-1)
    var required=Int(n)-1
    for i in range(1,Int(n)+1):
        var x=phi[i];required+=1
        while x>=10:x/=10;required+=1
    var out=InlineArray[UInt8,400]()
    var pos=0
    for i in range(1,Int(n)+1):
        if i>1:out[pos]=44;pos+=1
        var x=phi[i];var digits=InlineArray[Int,3]();var count=0
        while True:digits[count]=x%10;count+=1;x/=10;if x==0:break
        while count>0:count-=1;out[pos]=UInt8(48+digits[count]);pos+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(required):return -2
    for i in range(pos):o[i]=out[i]
    return Int64(pos)
