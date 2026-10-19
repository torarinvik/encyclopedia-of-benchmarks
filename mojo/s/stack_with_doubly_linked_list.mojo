from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("stack_with_doubly_linked_list")
fn stack_with_doubly_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129:return -1
    let oc=v[0]
    if oc<0 or oc>64:return -1
    var ops=InlineArray[Int64,64](fill=0);var args=InlineArray[Int64,64](fill=0);var p=1
    for i in range(Int(oc)):
        if p>=Int(n):return -1
        let op=v[p];p+=1;ops[i]=op
        if op==1:
            if p>=Int(n) or v[p]< -2147483648 or v[p]>2147483647:return -1
            args[i]=v[p];p+=1
        elif op<2 or op>4:return -1
    if p!=Int(n):return -1
    var vals=InlineArray[Int64,65](fill=0);var next=InlineArray[Int,65](fill=0);var prev=InlineArray[Int,65](fill=0);var nodecount=0;var head=0;var rec=InlineArray[Int64,192](fill=0)
    for i in range(Int(oc)):
        let op=ops[i];var tag:Int64=2;var value:Int64=0
        if op==1:
            nodecount+=1;vals[nodecount]=args[i];next[nodecount]=head;prev[nodecount]=0
            if head!=0:prev[head]=nodecount
            head=nodecount
        elif op==2:
            if head!=0:tag=0;value=vals[head];head=next[head];if head!=0:prev[head]=0
        elif op==3:
            if head!=0:tag=0;value=vals[head]
        else:
            tag=0;var node=head
            while node!=0:value+=1;node=next[node]
        rec[3*i]=op;rec[3*i+1]=tag;rec[3*i+2]=value
    let bytes=Int(oc)*24
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(oc)*3):let bits=bitcast[UInt64](rec[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
