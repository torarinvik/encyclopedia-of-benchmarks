from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("generate_rule_30_grid")
fn generate_rule_30_grid(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let width=Int(v[0]);let generations=Int(v[1])
    if width<1 or width>64 or generations<1 or generations>64:return -1
    let total=width*generations
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(total):return -2
    var current=InlineArray[Int64,64](fill=0);var next=InlineArray[Int64,64](fill=0);current[width//2]=1
    for c in range(width):out[c]=UInt8(current[c])
    for g in range(1,generations):
        for c in range(width):
            let left=if c>0 then current[c-1] else 0
            let right=if c+1<width then current[c+1] else 0
            let pattern=Int(left*4+current[c]*2+right)
            next[c]=Int64((30>>pattern)&1)
        for c in range(width):current[c]=next[c];out[g*width+c]=UInt8(next[c])
    return Int64(total)
