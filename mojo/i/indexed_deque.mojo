from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("indexed_deque")
fn indexed_deque(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>513: return -1
    if input[0]<1 or input[0]>256: return -1
    let q=Int(input[0])
    if length!=c_size_t(1+2*q): return -1
    var items=InlineArray[Int64,256](fill=0)
    var answers=InlineArray[Int64,256](fill=0)
    var head=0; var size=0; var count=0
    for i in range(q):
        let op=input[1+2*i]; let arg=input[2+2*i]
        if op==0 or op==1:
            if arg < -1000000 or arg > 1000000 or size==256: return -1
            if op==0:
                head=(head+255)%256
                items[head]=arg
            else: items[(head+size)%256]=arg
            size+=1
        elif op==2 or op==3:
            if arg!=0 or size==0: return -1
            if op==2: head=(head+1)%256
            size-=1
        elif op==4:
            if arg<0 or arg>=Int64(size): return -1
            answers[count]=items[(head+Int(arg))%256]
            count+=1
        else: return -1
    if count==0: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(8*count): return -2
    for i in range(count):
        let bits=bitcast[UInt64](answers[i])
        for byte in range(8): output[8*i+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return Int64(8*count)
