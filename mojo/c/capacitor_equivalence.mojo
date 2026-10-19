from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("capacitor_equivalence")
fn capacitor_equivalence(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 33: return -1.0e300
    let operation = values[0]
    if operation != 0 and operation != 1: return -1.0e300
    var accumulated: Float64 = 0.0
    for i in range(1, length):
        let capacitor = values[i]
        if capacitor < (1 if operation == 1 else 0) or capacitor > 1000: return -1.0e300
        if operation == 0: accumulated += Float64(capacitor)
        else: accumulated += 1.0 / Float64(capacitor)
    return accumulated if operation == 0 else 1.0 / accumulated
