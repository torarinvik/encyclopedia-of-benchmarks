from std.memory import MutAnyOrigin, UnsafePointer
fn pn_isprime(x:Int)->Bool:
    if x<2:return False
    var d=2
    while d<=x//d:if x%d==0:return False;d+=1
    return True
fn pn_decimal(x:Int,out:UnsafePointer[UInt8,MutAnyOrigin],pos0:Int)->Int:
    var digits=InlineArray[UInt8,3](fill=0);var k=0;var n=x
    while n>0:digits[k]=UInt8(n%10);k+=1;n//=10
    var pos=pos0
    for i in range(k):out[pos]=48+digits[k-1-i];pos+=1
    return pos
@export("prime_numbers")
fn prime_numbers(limit:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],cap:UInt64) abi("C")->Int64:
    if limit<0 or limit>80:return -1
    var need=0;var count=0
    for x in range(2,Int(limit)+1):
        if pn_isprime(x):
            var d=x;var digits=1
            while d>=10:d//=10;digits+=1
            need+=digits+(1 if count>0 else 0);count+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<UInt64(need):return -2
    var pos=0;count=0
    for x in range(2,Int(limit)+1):
        if pn_isprime(x):
            if count>0:out[pos]=44;pos+=1
            pos=pn_decimal(x,out,pos);count+=1
    return Int64(pos)
