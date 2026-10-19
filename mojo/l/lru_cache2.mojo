from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
comptime LC2_OPS=256
comptime LC2_CAP=64
fn lc2_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("lru_cache2")
fn lru_cache2(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>771:return -1
    let capacity=v[0];let ops=v[1]
    if capacity<2 or capacity>LC2_CAP or ops<0 or ops>LC2_OPS or n!=c_size_t(2+3*ops):return -1
    var keys=InlineArray[Int64,LC2_CAP](fill=0);var vals=InlineArray[Int64,LC2_CAP](fill=0);var order=InlineArray[Int64,LC2_CAP](fill=0);var used=0
    var seen=InlineArray[Int64,LC2_OPS](fill=0);var seen_n=0;var result=InlineArray[Int64,LC2_OPS](fill=0)
    for i in range(Int(ops)):
        let p=2+3*i;let op=v[p];let a=v[p+1];let b=v[p+2]
        if op<0 or op>4:return -1
        if op==0:
            if a < -2147483648 or a>2147483647 or b < -2147483648 or b>2147483647:return -1
            for j in range(seen_n):if seen[j]==a:return -1
            seen[seen_n]=a;seen_n+=1
            var slot=0
            if used<Int(capacity):slot=used;used+=1
            else:slot=Int(order[used-1])
            keys[slot]=a;vals[slot]=b
            for j in range(used-1,0,-1):order[j]=order[j-1]
            order[0]=Int64(slot);result[i]= -9223372036854775808
        elif op==1:
            if a < -2147483648 or a>2147483647 or b!=0:return -1
            var at=0
            while at<used and keys[Int(order[at])]!=a:at+=1
            if at==used:return -1
            let slot=Int(order[at]);result[i]=vals[slot]
            for j in range(at,0,-1):order[j]=order[j-1]
            order[0]=Int64(slot)
        else:
            if a!=0 or b!=0:return -1
            if op==2:result[i]=Int64(used)
            elif op==3:result[i]=capacity
            else:result[i]=Int64(used==0)
    let bytes=Int(ops)*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(ops)):lc2_put(o,i*8,result[i])
    return Int64(bytes)
