from std.ffi import c_size_t
from std.math import log
from std.memory import ImmutAnyOrigin, UnsafePointer

const INVALID_RESULT = -1.0e300

@export("hickerson_almost_integer")
fn hickerson_almost_integer(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return INVALID_RESULT
    let n = values[0]
    if n < 1 or n > 17:
        return INVALID_RESULT
    let log_two = log(2.0)
    var value = 1.0 / (2.0 * log_two * log_two)
    for index in range(2, Int(n) + 1):
        value = (Float64(index) / log_two) * value
    value
