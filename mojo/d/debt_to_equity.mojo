from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("debt_to_equity")
fn debt_to_equity(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1.0e300
    if values[0]<0 or values[0]>1000000 or values[1]<1 or values[1]>1000000:return -1.0e300
    return Float64(values[0])/Float64(values[1])
