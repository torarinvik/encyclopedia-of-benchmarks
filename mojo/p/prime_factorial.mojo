from std.memory import MutAnyOrigin, UnsafePointer
@export("prime_factorial")
fn prime_factorial(n:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],cap:UInt64) abi("C")->Int64:
    if n<2 or n>4096:return -1
    var factors=InlineArray[UInt32,5](fill=0);var count=0
    for c in range(2,Int(n)+1):
        var prime=True
        for d in range(2,c//2+2):if c%d==0:prime=False;break
        if prime and n%Int64(c)==0:factors[count]=UInt32(c);count+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<UInt64(count*4):return -2
    for i in range(count):for b in range(4):out[i*4+b]=UInt8((factors[i]>>(8*b))&255)
    return Int64(count*4)
