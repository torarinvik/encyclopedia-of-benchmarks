from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ceil_division(numerator: Int64, denominator: Int64) -> Int64:
    if numerator >= 0:
        var result = numerator // denominator
        if numerator % denominator != 0: result += 1
        return result
    return -((-numerator) // denominator)

@export("ceil_benchmark")
fn ceil_benchmark(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 513: return -1
    let count = values[0]
    if count < 0 or count > 256 or length != 1 + 2 * count: return -1
    for i in range(count):
        let numerator = values[1 + 2 * i]
        let denominator = values[2 + 2 * i]
        if numerator < -1000000000000 or numerator > 1000000000000 or denominator < 1 or denominator > 1000000: return -1
    var checksum: Int64 = 0
    for i in range(count): checksum += (i + 1) * (ceil_division(values[1 + 2 * i], values[2 + 2 * i]) + 1000000000001)
    return checksum
