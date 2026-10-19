from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn java_next(mut state:UInt64,bound:UInt32)->UInt32:
    if (bound&(bound-1))==0:
        state=(state*UInt64(0x5DEECE66D)+UInt64(11))&UInt64(0xffffffffffff)
        let bits=UInt32(state>>17)
        return UInt32((UInt64(bound)*UInt64(bits))>>31)
    while True:
        state=(state*UInt64(0x5DEECE66D)+UInt64(11))&UInt64(0xffffffffffff)
        let bits=UInt32(state>>17);let value=bits%bound
        if UInt64(bits)-UInt64(value)+UInt64(bound-1)<=UInt64(2147483647):return value
    return 0
fn put64rrc(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[at+j]=UInt8((b>>(8*j))&UInt64(255))
@export("rrcache")
fn rrcache(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>99 or v[0]<1 or v[0]>8 or v[2]<0 or v[2]>32 or Int(n)!=3+3*Int(v[2]):return -1
    let capacity=Int(v[0]);let q=Int(v[2]);var keys=InlineArray[Int64,8](fill=0);var vals=InlineArray[Int64,8](fill=0);var results=InlineArray[Int64,32](fill=0);var size=0
    var state=(bitcast[UInt64](v[1])^UInt64(0x5DEECE66D))&UInt64(0xffffffffffff)
    for opi in range(q):
        let at=3+3*opi;let op=v[at];let key=v[at+1];let value=v[at+2]
        if op==0:
            if key<1 or key>1024 or value<100 or value>1000000:return -1
            var idx=0
            while idx<size and keys[idx]!=key:idx+=1
            if idx<size:vals[idx]=value
            else:
                if size==capacity:
                    let evicted=Int(java_next(state,UInt32(size)))
                    for j in range(evicted,size-1):keys[j]=keys[j+1];vals[j]=vals[j+1]
                    size-=1
                keys[size]=key;vals[size]=value;size+=1
            results[opi]= -2
        elif op==1:
            if key<1 or key>1024 or value!=0:return -1
            var idx=0
            while idx<size and keys[idx]!=key:idx+=1
            results[opi]=if idx<size:vals[idx] else:-1
        elif op==2:
            if key!=0 or value!=0:return -1
            results[opi]=Int64(size)
        else:return -1
    let bytes=q*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(q):put64rrc(o,i*8,results[i])
    return Int64(bytes)
