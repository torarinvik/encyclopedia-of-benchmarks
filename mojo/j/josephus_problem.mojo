from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("josephus_problem")
fn josephus_problem(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let count=v[0];let step=v[1];if count<1 or count>100000 or step<1:return -1
    var winner:Int64=0
    for size in range(1,Int(count)+1):winner=(winner+step%Int64(size))%Int64(size)
    return winner+1
