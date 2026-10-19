from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("linked_stack")
fn linked_stack(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>64:return -1
    let ops=Int(v[0]);var codes=InlineArray[Int64,64](fill=0);var args=InlineArray[Int64,64](fill=0);var cursor=1
    for i in range(ops):
        if cursor>=Int(n):return -1
        let op=v[cursor];cursor+=1;codes[i]=op
        if op==1:
            if cursor>=Int(n) or v[cursor] < -2147483648 or v[cursor]>2147483647:return -1
            args[i]=v[cursor];cursor+=1
        elif op<2 or op>4:return -1
    if cursor!=Int(n):return -1
    var nodes=InlineArray[Int64,65](fill=0);var below=InlineArray[Int64,65](fill=0);var nodecount=0;var head=0;var buffer=InlineArray[UInt8,1536](fill=UInt8(0));var written=0
    for i in range(ops):
        let op=codes[i];var tag:Int64=2;var value:Int64=0
        if op==1:
            nodecount+=1;nodes[nodecount]=args[i];below[nodecount]=Int64(head);head=nodecount
        elif op==2:
            if head!=0:tag=0;value=nodes[head]
        elif op==3:
            if head!=0:tag=0;value=nodes[head];head=Int(below[head])
        else:tag=1;value=Int64(head==0)
        for field in range(3):
            let x=if field==0:op elif field==1:tag else:value;let bits=UInt64(x)
            for j in range(8):buffer[written+field*8+j]=UInt8((bits>>(8*j))&255)
        written+=24
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(written):return -2
    for i in range(written):out[i]=buffer[i]
    return Int64(written)
