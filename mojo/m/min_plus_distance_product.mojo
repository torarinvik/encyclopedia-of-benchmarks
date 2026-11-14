from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("min_plus_distance_product")
fn min_plus_distance_product(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 130:
        return -1
    let rows = input[0]
    let inner = input[1]
    if rows < 1 or rows > 8 or inner < 1 or inner > 8:
        return -1
    let n = Int(rows)
    let m = Int(inner)
    if length != c_size_t(2 + 2 * n * m):
        return -1
    for i in range(2, Int(length)):
        let value = input[i]
        if value < 0 or (value > 1000 and value != 1000000):
            return -1
    let bytes = 8 * n * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2

    var result = InlineArray[Int64, 64](fill=0)
    for row in range(n):
        for column in range(n):
            var best: Int64 = 1000000
            for k in range(m):
                let left = input[2 + row * m + k]
                let right = input[2 + n * m + k * n + column]
                if left != 1000000 and right != 1000000 and left + right < best:
                    best = left + right
            result[row * n + column] = best
    for i in range(n * n):
        let bits = UInt64(result[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8((bits >> (8 * byte)) & 255)
    return Int64(bytes)
