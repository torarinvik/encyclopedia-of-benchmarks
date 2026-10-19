from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn mq_byte(h:UInt64,x:Int64)->UInt64:
    let u=UInt32(Int32(x))
    var r=h
    for b in range(4):r=(r^UInt64((u>>(8*b))&255))*1099511628211
    return r
@export("monotonic_queue")
fn monotonic_queue(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4098:return -1
    let count=Int(v[0]);let window=Int(v[1]);if count<1 or count>4096 or window<1 or window>count or Int(n)!=count+2:return -1
    var dq=InlineArray[Int64,4096](fill=0);var head=0;var tail=0
    for i in range(count):if v[2+i] < -2147483648 or v[2+i]>2147483647:return -1
    var h:UInt64=14695981039346656037
    for i in range(count):
        while head<tail and dq[head]+Int64(window)<=Int64(i):head+=1
        while head<tail and v[2+Int(dq[tail-1])]<=v[2+i]:tail-=1
        dq[tail]=Int64(i);tail+=1
        if i+1>=window:h=mq_byte(h,v[2+Int(dq[head])])
    return Int64(h&0x7fffffffffffffff)
