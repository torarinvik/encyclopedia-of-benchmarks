from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn queue_put32(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=bitcast[UInt32](x)
    for j in range(4):out[at+j]=UInt8((b>>(8*j))&255)
@export("linked_queue_fifo_trace")
fn linked_queue_fifo_trace(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let ops=v[0]
    if ops<0 or ops>127 or n!=c_size_t(1+2*ops):return -1
    var vals=InlineArray[Int32,127](fill=0);var next=InlineArray[Int64,127](fill=-1);var results=InlineArray[Int32,127](fill=0)
    var head= -1;var rear= -1;var nodes=0;var count=0;var closed=False
    for i in range(Int(ops)):
        let op=v[1+2*i];let arg=v[2+2*i]
        if op==0:
            if closed or arg < -2147483648 or arg>2147483647 or nodes>=127:return -1
            let node=nodes;nodes+=1;vals[node]=Int32(arg);next[node]= -1
            if head<0:head=node
            else:next[rear]=Int64(node)
            rear=node
        elif op==1:
            if arg!=0 or head<0:return -1
            results[count]=vals[head];count+=1;head=Int(next[head])
            if head<0:rear= -1;closed=True
        else:return -1
    while head>=0:results[count]=vals[head];count+=1;head=Int(next[head])
    let bytes=count*4
    if bytes>0 and (out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes)):return -2
    for i in range(count):queue_put32(out,i*4,results[i])
    return Int64(bytes)
