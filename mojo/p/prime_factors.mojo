from std.memory import MutAnyOrigin, UnsafePointer
fn pf_append(x:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],at:Int)->Int:
    var ds=InlineArray[UInt8,12](fill=0);var k=0;var v=x
    while v>0:ds[k]=UInt8(v%10);k+=1;v//=10
    for i in range(k):out[at+i]=48+ds[k-1-i]
    return at+k
@export("prime_factors")
fn prime_factors(n:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],cap:UInt64) abi("C")->Int64:
    if n<1 or n>2147483647:return -1
    var rem=n;var factors=InlineArray[Int64,32](fill=0);var count=0;var d=Int64(2)
    while d<=rem//d:
        while rem%d==0:factors[count]=d;count+=1;rem//=d
        d+=1
    if rem>1:factors[count]=rem;count+=1
    var needed=0
    for i in range(count):
        if i>0:needed+=1
        var x=factors[i];needed+=1
        while x>=10:x//=10;needed+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<UInt64(needed):return -2
    var pos=0
    for i in range(count):
        if i>0:out[pos]=44;pos+=1
        pos=pf_append(factors[i],out,pos)
    return Int64(pos)
