from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("max_increase_keeping_skyline")
fn max_increase_keeping_skyline(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2501 or v[0]<2 or v[0]>50:return -1
    let d=Int(v[0]);if n!=c_size_t(1+d*d):return -1
    var rows=InlineArray[Int64,50](fill=0);var cols=InlineArray[Int64,50](fill=0)
    for r in range(d):for c in range(d):
        let x=v[1+r*d+c];if x<0 or x>100:return -1
        if x>rows[r]:rows[r]=x
        if x>cols[c]:cols[c]=x
    var total:Int64=0
    for r in range(d):for c in range(d):
        let top=rows[r] if rows[r]<cols[c] else cols[c]
        total+=top-v[1+r*d+c]
    return total
