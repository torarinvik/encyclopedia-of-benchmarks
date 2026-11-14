from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("mibench_automotive_basicmath_isqrt")
fn mibench_automotive_basicmath_isqrt(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    let value = input[0]
    if value < 0 or value > 65535:
        return -1

    # Feed the integer's 32 bits followed by 32 zero fractional bits.
    var remaining = UInt64(value)
    var root: UInt64 = 0
    var remainder: UInt64 = 0
    for _ in range(32):
        remainder = (remainder << 2) + (remaining >> 30)
        remaining = (remaining << 2) & UInt64(0xffffffff)
        root <<= 1
        let trial = 2 * root + 1
        if remainder >= trial:
            remainder -= trial
            root += 1
    return Int64(root)
