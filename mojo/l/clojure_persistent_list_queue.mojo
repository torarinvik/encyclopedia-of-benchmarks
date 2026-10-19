from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn queue_hash_byte(h:UInt64,b:UInt8)->UInt64:
    return (h ^ UInt64(b))*UInt64(1099511628211)
fn queue_hash_u16(h0:UInt64,x:UInt64)->UInt64:
    var h=h0
    for i in range(2):h=queue_hash_byte(h,UInt8((x>>(8*i))&255))
    return h
fn queue_hash_i64(h0:UInt64,x:Int64)->UInt64:
    var h=h0;let u=UInt64(x)
    for i in range(8):h=queue_hash_byte(h,UInt8((u>>(8*i))&255))
    return h

@export("clojure_persistent_list_queue")
fn clojure_persistent_list_queue(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>514:return -1
    let ops=v[0]
    if ops<0 or ops>256 or n!=c_size_t(1+2*ops):return -1
    var q=InlineArray[Int64,64](fill=0);var results=InlineArray[Int64,256](fill=0);var codes=InlineArray[UInt8,256](fill=UInt8(0));var size=0
    for oi in range(Int(ops)):
        let code=v[1+2*oi];let arg=v[2+2*oi]
        if code<0 or code>3:return -1
        codes[oi]=UInt8(code)
        if code==0:
            if arg< -2147483648 or arg>2147483647 or size>=64:return -1
            var k=size
            while k>0:q[k]=q[k-1];k-=1
            q[0]=arg;size+=1;results[oi]=Int64(size)
        elif code==1:
            if arg!=0:return -1
            if size>0:size-=1
            results[oi]=Int64(size)
        elif code==2:
            if arg!=0:return -1
            results[oi]=if size==0: -9223372036854775808 else:q[size-1]
        else:
            if arg!=0:return -1
            results[oi]=if size==0:1 else:0
    var h=UInt64(14695981039346656037)
    h=queue_hash_u16(h,UInt64(ops))
    for i in range(Int(ops)):
        h=queue_hash_byte(h,codes[i]);h=queue_hash_i64(h,results[i])
    h=queue_hash_u16(h,UInt64(size))
    for ri in range(size):h=queue_hash_byte(h,UInt8((UInt64(q[size-1-ri])>>0)&255));h=queue_hash_byte(h,UInt8((UInt64(q[size-1-ri])>>8)&255));h=queue_hash_byte(h,UInt8((UInt64(q[size-1-ri])>>16)&255));h=queue_hash_byte(h,UInt8((UInt64(q[size-1-ri])>>24)&255))
    return Int64(h & UInt64(0x7fffffffffffffff))
