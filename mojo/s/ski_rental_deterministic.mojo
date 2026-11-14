from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("ski_rental_deterministic")
fn ski_rental_deterministic(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let rent = input[0]; let purchase = input[1]; let trips = input[2]
    if rent < 1 or rent > 32 or purchase < 1 or purchase > 64 or trips < 0 or trips > 32: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(trips): return -2
    let threshold = purchase // rent
    for trip in range(Int(trips)):
        var action = UInt8(0)
        if Int64(trip) == threshold: action = 1
        elif Int64(trip) > threshold: action = 2
        output[trip] = action
    return trips
