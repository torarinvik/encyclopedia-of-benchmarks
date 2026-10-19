from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("endianness")
fn endianness(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>10:return -1
    let mode=input[0]
    if mode==0:
        if length!=2 or input[1]<0 or input[1]>65535:return -1
        let x=UInt64(input[1]);return Int64(((x&255)<<8)|((x>>8)&255))
    if mode==1:
        if length!=2 or input[1]<0 or input[1]>4294967295:return -1
        let x=UInt64(input[1]);return bitcast[Int64](((x&255)<<24)|((x&65280)<<8)|((x>>8)&65280)|((x>>24)&255))
    if mode==2:
        if length!=2:return -1
        let x=bitcast[UInt64](input[1]);var out:UInt64=0
        for i in range(8):out|=((x>>(8*i))&255)<<(8*(7-i))
        return bitcast[Int64](out)
    if mode==3 or mode==4:
        if length<3:return -1
        let count=input[1]
        if count<1 or count>8 or length!=c_size_t(2+count):return -1
        var out:UInt64=0
        for i in range(Int(count)):
            let b=input[2+i]
            if b<0 or b>255:return -1
            if mode==3:out|=UInt64(b)<<(8*i)
            else:out=(out<<8)|UInt64(b)
        return bitcast[Int64](out)
    if mode==5 or mode==6:
        if length!=3:return -1
        let value=bitcast[UInt64](input[1]);let count=input[2]
        if count<1 or count>8:return -1
        if count<8 and value>>(8*Int(count))!=0:return -1
        var packed:UInt64=0
        for i in range(Int(count)):
            let b=if mode==5:(value>>(8*i))&255 else (value>>(8*(Int(count)-1-i)))&255
            packed|=b<<(8*i)
        return bitcast[Int64](packed)
    return -1
