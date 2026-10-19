from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("binary_addition")
fn binary_addition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let av = input[0]; let bv = input[1]
    if av < 0 or av > 2047 or bv < 0 or bv > 2047 or length != c_size_t(2 + av + bv): return -1
    let a = Int(av); let b = Int(bv); let width = max(a, b)
    for i in range(a + b):
        if input[2 + i] < 0 or input[2 + i] > 1: return -1
    var carry = 0
    for off in range(width):
        let x = input[2 + a - 1 - off] if off < a else 0
        let y = input[2 + a + b - 1 - off] if off < b else 0
        carry = Int((x + y + carry) >> 1)
    let result_len = width + carry
    if result_len == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(result_len): return -2
    carry = 0
    for off in range(width):
        let x = input[2 + a - 1 - off] if off < a else 0
        let y = input[2 + a + b - 1 - off] if off < b else 0
        let sum = Int(x + y) + carry
        output[result_len - 1 - off] = UInt8(48 + (sum & 1))
        carry = sum >> 1
    if carry != 0: output[0] = UInt8(49)
    return Int64(result_len)
