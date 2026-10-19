from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("electric_conductivity")
fn electric_conductivity(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let conductivity=input[0]; let electrons=input[1]; let mobility=input[2]
    if conductivity<0 or conductivity>1000 or electrons<0 or electrons>1000 or mobility<0 or mobility>1000: return -1.0e300
    var zeros=0
    if conductivity==0: zeros+=1
    if electrons==0: zeros+=1
    if mobility==0: zeros+=1
    if zeros != 1: return -1.0e300
    let charge=1.6021e-19
    if conductivity==0: return Float64(mobility)*Float64(electrons)*charge
    if electrons==0: return Float64(conductivity)/(Float64(mobility)*charge)
    return Float64(conductivity)/(Float64(electrons)*charge)
