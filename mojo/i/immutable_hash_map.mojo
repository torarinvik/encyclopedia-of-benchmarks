from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn ihm_feed(h0:UInt64,value:Int64)->UInt64:
    var h=h0;let bits=UInt64(value)
    for b in range(8):h=(h^UInt64(UInt8((bits>>(8*b))&255)))*1099511628211
    return h
@export("immutable_hash_map")
fn immutable_hash_map(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>769:return -1
    let n=input[0]
    if n<0 or n>256 or length!=c_size_t(1+3*n):return -1
    var keys=InlineArray[Int32,256](fill=0);var vals=InlineArray[Int32,256](fill=0)
    var trace=InlineArray[Int64,256](fill=0);var size=0
    for i in range(Int(n)):
        let op=input[1+3*i];let k=input[2+3*i];let v=input[3+3*i]
        if op<0 or op>3 or k< -2147483648 or k>2147483647 or v< -2147483648 or v>2147483647:return -1
        if op==0:
            if v==0:return -1
            keys[size]=Int32(k);vals[size]=Int32(v);size+=1;trace[i]=Int64(size)
        elif op==1 or op==2:
            var found=0;var foundv:Int32=0;var j=size
            while j>0:
                j-=1
                if keys[j]==Int32(k):found=1;foundv=vals[j];break
            trace[i]=Int64(foundv) if op==1 else Int64(found)
        else:trace[i]=Int64(size)
    var h=UInt64(14695981039346656037)
    h=ihm_feed(h,n)
    for i in range(Int(n)):h=ihm_feed(h,trace[i])
    return Int64(h&0x7fffffffffffffff)
