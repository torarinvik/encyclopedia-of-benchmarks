from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn narc_power(d:Int,expn:Int)->Int64:
    var p:Int64=1
    for _ in range(expn):p*=d
    return p
@export("narcissistic_number")
fn narcissistic_number(limit:Int64,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if limit>100000:return -1
    if limit<=0:return 0
    var numbers=InlineArray[Int64,32]();var count=0
    for x in range(Int(limit)):
        var digits=1;var q=x
        while q>=10:q//=10;digits+=1
        var sum:Int64=0;q=x
        while q>0:sum+=narc_power(q%10,digits);q//=10
        if sum==x:numbers[count]=x;count+=1
    let bytes=count*8
    if bytes==0:return 0
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        let bits=UInt64(numbers[i])
        for b in range(8):o[8*i+b]=UInt8((bits>>(8*(7-b)))&255)
    return bytes
