from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("peak")
fn peak(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>65 or v[0]<3 or v[0]>64 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var turn=1
    for i in range(count):if v[i+1] < -1000000 or v[i+1]>1000000:return -1
    while turn<count and v[turn+1]>v[turn]:turn+=1
    if turn==1 or turn>=count:return -1
    for i in range(turn,count):if v[i+1]>=v[i]:return -1
    return v[turn]
