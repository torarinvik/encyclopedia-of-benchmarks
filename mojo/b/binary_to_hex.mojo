from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("binary_to_hex")
fn binary_to_hex(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(Int(length)):
        if input[i] != 48 and input[i] != 49: return -1
    let n = Int(length); let out_n = (n + 3) // 4
    if out_n == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(out_n): return -2
    let first_width = (n % 4) if (n % 4) != 0 else 4
    var start = 0
    for group in range(out_n):
        let width = first_width if group == 0 else 4; var nibble = 0
        for off in range(width): nibble = nibble * 2 + Int(input[start + off] - 48)
        output[group] = UInt8(48 + nibble) if nibble < 10 else UInt8(55 + nibble)
        start += width
    return Int64(out_n)
