from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hash_set")
fn hash_set(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let adds=a[0];if adds<0 or adds>64 or n<c_size_t(adds+2):return -1
    let qpos=1+Int(adds);let q=a[qpos]
    if q<0 or q>64 or n!=c_size_t(qpos+1+q):return -1
    var present=InlineArray[Bool,64](fill=false)
    for i in range(Int(adds)):
        let id=a[1+i];if id<0 or id>63:return -1
        present[Int(id)]=true
    var h:UInt64=14695981039346656037
    let total=1+Int(q)
    for j in range(total):
        let word:Int64=if j==0: Int64(present_count(present)) else:
            let id=a[qpos+j];if id<0 or id>63:return -1
            1 if present[Int(id)] else 0
        let bits=bitcast[UInt64](word)
        for b in range(8):h=(h^((bits>>UInt(8*b))&255))*1099511628211
    return Int64(h&0x7fffffffffffffff)
fn present_count(p:InlineArray[Bool,64])->Int:
    var c=0
    for i in range(64):if p[i]:c+=1
    return c
