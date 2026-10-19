from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("one_hot_encode")
fn one_hot_encode(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>33 or v[0]<1 or v[0]>32 or n!=c_size_t(v[0]+1):return -1
    let rows=Int(v[0]);var present=InlineArray[Int64,26](fill=0)
    for i in range(rows):
        if v[i+1]<0 or v[i+1]>25:return -1
        present[Int(v[i+1])]=1
    var cols=0
    for c in range(26):if present[c]!=0:cols+=1
    let need=rows*cols
    if cap<c_size_t(need) or (need>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var map=InlineArray[Int64,26](fill=0);var col=0
    for c in range(26):if present[c]!=0:map[c]=Int64(col);col+=1
    for r in range(rows):
        let selected=Int(map[Int(v[r+1])])
        for c in range(cols):o[r*cols+c]=UInt8(Int(c==selected))
    return Int64(need)
