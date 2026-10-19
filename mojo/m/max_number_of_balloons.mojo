from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("max_number_of_balloons")
fn max_number_of_balloons(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var counts=InlineArray[Int64,5](fill=0)
    for i in range(Int(n)):
        let x=v[i];if x<97 or x>122:return -1
        if x==98:counts[0]+=1
        elif x==97:counts[1]+=1
        elif x==108:counts[2]+=1
        elif x==111:counts[3]+=1
        elif x==110:counts[4]+=1
    counts[2]/=2;counts[3]/=2
    var minimum=counts[0]
    for i in range(1,5):if counts[i]<minimum:minimum=counts[i]
    return minimum
