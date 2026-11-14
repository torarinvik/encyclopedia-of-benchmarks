from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("versabench_dbms_keys_union")
fn versabench_dbms_keys_union(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 130: return -1
    let count = input[0]
    if count < 1 or count > 16 or length != c_size_t(1 + 8 * count): return -1
    var lower = InlineArray[Int64, 4](fill=8)
    var upper = InlineArray[Int64, 4](fill=-8)
    for i in range(Int(count)):
        for d in range(4):
            let lo = input[1 + 8 * i + d]
            let hi = input[5 + 8 * i + d]
            if lo < -8 or lo > 8 or hi < -8 or hi > 8 or lo > hi: return -1
            lower[d] = min(lower[d], lo)
            upper[d] = max(upper[d], hi)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 64: return -2
    for slot in range(8):
        let value = if slot < 4: lower[slot] else: upper[slot - 4]
        var bits = bitcast[UInt64](value)
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return 64
