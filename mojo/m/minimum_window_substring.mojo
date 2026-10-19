from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("minimum_window_substring")
fn minimum_window_substring(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>258 or v[0]<0 or v[0]>128:return -1
    let s=Int(v[0]);if Int(n)<s+2:return -1
    let m=v[s+1];if m<1 or m>128 or Int(n)!=s+Int(m)+2:return -1
    var need=InlineArray[Int64,128](fill=0)
    for i in range(s):if v[i+1]<0 or v[i+1]>127:return -1
    for i in range(Int(m)):
        let x=v[s+2+i]
        if x<0 or x>127:return -1
        need[Int(x)]+=1
    var left=0;var best=s+1;var start=0;var missing=Int(m)
    for right in range(s):
        let x=Int(v[right+1])
        if need[x]>0:missing-=1
        need[x]-=1
        while missing==0:
            let size=right-left+1
            if size<best:best=size;start=left
            let y=Int(v[left+1]);need[y]+=1;left+=1
            if need[y]>0:missing+=1
    if best==s+1:return 0
    if cap<c_size_t(best) or (best>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(best):out[i]=UInt8(v[start+1+i])
    return Int64(best)
