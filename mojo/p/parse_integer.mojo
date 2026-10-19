from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("parse_integer")
fn parse_integer(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>64:return -9223372036854775808
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -9223372036854775808
    let negative=v[0]==45;var pos=if v[0]==45 or v[0]==43:1 else:0;var number:UInt32=0
    for i in range(pos,Int(n)):
        if v[i]<48 or v[i]>57:return -9223372036854775808
        number=number*10+UInt32(v[i]-48)
    if negative:number=0-number
    return Int64(number) if number<=2147483647 else Int64(number)-4294967296
