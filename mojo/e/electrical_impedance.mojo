from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt

@export("electrical_impedance")
fn electrical_impedance(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let resistance=input[0]; let reactance=input[1]; let impedance=input[2]
    if resistance<0 or resistance>1000 or reactance<0 or reactance>1000 or impedance<0 or impedance>1000: return -1.0e300
    var zeros=0
    if resistance==0: zeros+=1
    if reactance==0: zeros+=1
    if impedance==0: zeros+=1
    if zeros != 1: return -1.0e300
    if resistance==0:
        let rad=impedance*impedance-reactance*reactance
        if rad<0: return -1.0e300
        return sqrt(Float64(rad))
    if reactance==0:
        let rad=impedance*impedance-resistance*resistance
        if rad<0: return -1.0e300
        return sqrt(Float64(rad))
    return sqrt(Float64(resistance*resistance+reactance*reactance))
