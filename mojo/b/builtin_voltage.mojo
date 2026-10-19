from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import log

@export("builtin_voltage")
fn builtin_voltage(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1.0e300
    let donor=values[0];let acceptor=values[1];let intrinsic=values[2]
    if donor<1 or donor>1000 or acceptor<1 or acceptor>1000 or intrinsic<1 or intrinsic>1000 or donor<=intrinsic or acceptor<=intrinsic:return -1.0e300
    let ratio=Float64(donor)*Float64(acceptor)/(Float64(intrinsic)*Float64(intrinsic))
    return 1.380649e-23*300.0*log(ratio)/1.602176634e-19
