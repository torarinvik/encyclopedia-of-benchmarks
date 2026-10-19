from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("hashmap")
fn hashmap(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let capacity=a[0];let ops=a[1]
    if capacity<1 or capacity>64 or (capacity&(capacity-1))!=0 or ops<0 or ops>128 or n!=c_size_t(2+3*ops):return -1
    var keys=InlineArray[Int64,128](fill=0);var vals=InlineArray[Int64,128](fill=0);var size=0;var capnow=Int(capacity)
    var outputs=InlineArray[Int64,392](fill=0);var q=0;var query_count=0
    for i in range(Int(ops)):
        let op=a[2+3*i];let key=a[3+3*i];let value=a[4+3*i]
        if op<0 or op>2 or key< -2147483648 or key>2147483647 or value< -2147483648 or value>2147483647:return -1
        var found=-1
        for j in range(size):if keys[j]==key:found=j
        if op==0:
            if found>=0:vals[found]=value
            else:
                keys[size]=key;vals[size]=value;size+=1
                if Float64(size)/Float64(capnow)>0.75:capnow*=2
        else:
            if value!=0:return -1
            query_count+=1
            outputs[1+q]=op
            if op==1:
                outputs[2+q]=1 if found>=0 else 0;outputs[3+q]=vals[found] if found>=0 else 0;q+=3
            else:outputs[2+q]=1 if found>=0 else 0;q+=2
    outputs[0]=Int64(query_count)
    outputs[q+1]=Int64(size);outputs[q+2]=Int64(capnow)
    let bytes=(q+3)*8
    if cap<c_size_t(bytes) or out==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(q+3):
        let u=bitcast[UInt64](outputs[i])
        for b in range(8):out[i*8+b]=UInt8((u>>UInt(8*b))&255)
    return Int64(bytes)
