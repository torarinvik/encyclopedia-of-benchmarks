from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("pattern_matching")
fn pattern_matching(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>130 or v[0]<0 or v[0]>64:return -1
    let t=Int(v[0]);let po=t+1;if Int(n)<po+1 or v[po]<1 or v[po]>64:return -1
    let p=Int(v[po]);if Int(n)!=po+p+1 or p>t:return -1
    for i in range(t):if v[i+1]<0 or v[i+1]>127:return -1
    for i in range(p):if v[po+1+i]<0 or v[po+1+i]>127:return -1
    for i in range(t-p+1):
        var j=0;while j<p and v[i+1+j]==v[po+1+j]:j+=1
        if j==p:return Int64(i)
    return -1
