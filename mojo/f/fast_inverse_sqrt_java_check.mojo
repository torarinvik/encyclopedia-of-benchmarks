from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("fast_inverse_sqrt_java_check")
fn fast_inverse_sqrt_java_check(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    if input[0] == 0:
        if input[1] < 0x00800000 or input[1] > 0x7f7fffff: return -1
        let bits = UInt32(input[1])
        let number = bitcast[Float32](bits)
        let xhalf = Float32(Float32(0.5) * number)
        var seed = Int32(bits) 
        seed = Int32(0x5f3759df) - (seed >> 1)
        var x = bitcast[Float32](UInt32(seed))
        x = Float32(x * Float32(Float32(1.5) - Float32(xhalf * x * x)))
        let expected = Float32(1.0) / Float32(sqrt(Float64(number)))
        return 1 if x == expected else 0
    elif input[0] == 1:
        if input[1] < 0x0010000000000000 or input[1] > 0x7fefffffffffffff: return -1
        let bits = UInt64(input[1])
        let number = bitcast[Float64](bits)
        let xhalf = 0.5 * number
        var seed = Int64(bits)
        seed = Int64(0x5fe6ec85e7de30da) - (seed >> 1)
        var x = bitcast[Float64](UInt64(seed))
        for i in range(4): x = x * (1.5 - xhalf * x * x)
        x *= number
        return 1 if x == 1.0 / sqrt(number) else 0
    return -1
