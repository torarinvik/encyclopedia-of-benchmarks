from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn alternative_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8):
        output[pos + b] = UInt8((bits >> (8 * b)) & 255)

@export("alternative_list_arrange")
fn alternative_list_arrange(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 64:
        return -1
    let a = Int(input[0])
    if 1 + a >= Int(length) or input[1 + a] < 0 or input[1 + a] > 64:
        return -1
    let b = Int(input[1 + a])
    if length != c_size_t(2 + a + b): return -1
    let count = a + b
    if capacity < c_size_t(count * 8) or (count > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var out = 0
    for i in range(max(a, b)):
        if i < a:
            alternative_write_i64(output, out, input[1 + i]); out += 8
        if i < b:
            alternative_write_i64(output, out, input[2 + a + i]); out += 8
    return Int64(count)
