from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn morton_spread(value: UInt64) -> UInt64:
    var x = value
    x = (x | (x << 8)) & 0x00ff00ff
    x = (x | (x << 4)) & 0x0f0f0f0f
    x = (x | (x << 2)) & 0x33333333
    return (x | (x << 1)) & 0x55555555

@export("morton_sort")
fn morton_sort(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 513:
        return -1
    let count = input[0]
    if count < 1 or count > 256 or length != c_size_t(1 + 2 * count):
        return -1
    let n = Int(count)
    var keys = InlineArray[UInt64, 256](fill=0)
    var order = InlineArray[Int, 256](fill=0)
    for i in range(n):
        let x = input[1 + 2 * i]
        let y = input[2 + 2 * i]
        if x < 0 or x > 65535 or y < 0 or y > 65535:
            return -1
        keys[i] = morton_spread(UInt64(x)) | (morton_spread(UInt64(y)) << 1)
        order[i] = i
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    # Stable sorting retains the original order for equal Morton keys.
    for i in range(1, n):
        let item = order[i]
        var position = i
        while position > 0 and keys[order[position - 1]] > keys[item]:
            order[position] = order[position - 1]
            position -= 1
        order[position] = item
    for i in range(n):
        let bits = UInt64(order[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8((bits >> (8 * byte)) & 255)
    return Int64(bytes)
