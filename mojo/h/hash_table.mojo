from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ht_put(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,v:Int64):
    let u=bitcast[UInt64](v)
    for b in range(8):out[at+b]=UInt8((u>>UInt(8*b))&255)
@export("hash_table")
fn hash_table(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let m=a[0];if m<0 or m>8 or n<c_size_t(2+m):return -1
    let qp=1+Int(m);let q=a[qp];if q<1 or q>8 or n!=c_size_t(qp+1+q):return -1
    var used=InlineArray[Bool,1001](fill=false)
    var inserted=InlineArray[Bool,1001](fill=false)
    for i in range(Int(m)+Int(q)):
        let key=a[1+i] if i<Int(m) else a[qp+1+i-Int(m)]
        if key<1 or key>1000:return -1
        if i<Int(m) and inserted[Int(key)]:return -1
        if i<Int(m):inserted[Int(key)]=true
        for k in range(1,1001):
            if used[k] and k!=Int(key) and (k%17==Int(key)%17 or k%3000==Int(key)%3000):return -1
        used[Int(key)]=true
    var seenq=InlineArray[Bool,1001](fill=false)
    for i in range(Int(q)):
        let key=a[qp+1+i]
        if seenq[Int(key)]:return -1
        seenq[Int(key)]=true
    let bytes=Int(q)*8
    if cap<c_size_t(bytes) or (bytes>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(q)):ht_put(out,i*8,1 if inserted[Int(a[qp+1+i])] else 0)
    return Int64(bytes)
