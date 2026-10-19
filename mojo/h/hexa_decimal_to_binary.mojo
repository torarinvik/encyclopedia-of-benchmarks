from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("hexa_decimal_to_binary")
fn hexa_decimal_to_binary(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>64:return -1
    var i=0;var neg=false
    if a[0]==43 or a[0]==45:neg=a[0]==45;i=1
    if i==Int(n):return -1
    var value:UInt64=0
    for j in range(i,Int(n)):
        let c=a[j];var d:Int64=-1
        if c>=48 and c<=57:d=c-48
        elif c>=65 and c<=70:d=c-55
        elif c>=97 and c<=102:d=c-87
        if d<0:return -1
        value=value*16+UInt64(d)
    var signed:Int64=Int64(value)
    if neg:signed= -signed
    if signed< -2147483648 or signed>2147483647:return -1
    let bits=if signed<0:bitcast[UInt32](Int32(signed)) else:UInt32(signed)
    var width=8;var temp=bits
    if signed<0:width=32
    else:
        while temp>255:temp>>=1;width+=1
    if cap<c_size_t(width) or out==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for j in range(width):out[j]=UInt8(48+((bits>>UInt(width-1-j))&1))
    return Int64(width)
