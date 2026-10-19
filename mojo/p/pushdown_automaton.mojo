from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("pushdown_automaton")
fn pushdown_automaton(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>257:return -1
    let count64=values[0]
    if count64<0 or count64>256 or length!=c_size_t(count64+1):return -1
    let count=Int(count64)
    for i in range(count):
        if values[i+1]<48 or values[i+1]>50:return -1
    if count==0 or count%2!=0:return 0
    let half=count//2
    for i in range(half):
        if values[i+1]!=49 and values[i+1]!=50:return 0
    for i in range(half,count):
        if values[i+1]!=48:return 0
    return 1
