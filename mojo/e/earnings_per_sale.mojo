from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("earnings_per_sale")
fn earnings_per_sale(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let income = input[0]; let dividend = input[1]; let shares = input[2]
    if income < -1000000 or income > 1000000 or dividend < 0 or dividend > 1000000 or shares < 1 or shares > 1000000: return -1.0e300
    return Float64(income - dividend) / Float64(shares)
