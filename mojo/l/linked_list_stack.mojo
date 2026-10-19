from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn stack_put32(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=bitcast[UInt32](x)
    for i in range(4):out[at+i]=UInt8((b>>(8*i))&255)
@export("linked_list_stack")
fn linked_list_stack(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>64:return -1
    let ops=Int(v[0]);var nodes=InlineArray[Int32,64](fill=0);var next=InlineArray[Int32,64](fill=-1);var rec=InlineArray[Int32,128](fill=0);var node_count=0;var queries=0;var cursor=1;var top:Int32=-1;var size=0
    for _ in range(ops):
        if cursor>=Int(n):return -1
        let op=v[cursor];cursor+=1
        if op==0:
            if cursor>=Int(n):return -1
            let x=v[cursor];cursor+=1
            if x < -2147483648 or x>2147483647 or size>=64 or node_count>=64:return -1
            nodes[node_count]=Int32(x);next[node_count]=top;top=Int32(node_count);node_count+=1;size+=1
        elif op==1:
            if size==0 or top<0:return -1
            rec[2*queries]=1;rec[2*queries+1]=nodes[top];queries+=1;top=next[top];size-=1
        elif op==2:rec[2*queries]=2;rec[2*queries+1]=Int32(size);queries+=1
        elif op==3:rec[2*queries]=3;rec[2*queries+1]=if size==0:1 else:0;queries+=1
        else:return -1
    if cursor!=Int(n):return -1
    let bytes=4+8*queries
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var staged=InlineArray[UInt8,516](fill=UInt8(0))
    let countbits=UInt32(queries)
    for j in range(4):staged[j]=UInt8((countbits>>(8*j))&255)
    for i in range(2*queries):
        let bits=bitcast[UInt32](rec[i])
        for j in range(4):staged[4+4*i+j]=UInt8((bits>>(8*j))&255)
    for i in range(bytes):out[i]=staged[i]
    return Int64(bytes)
