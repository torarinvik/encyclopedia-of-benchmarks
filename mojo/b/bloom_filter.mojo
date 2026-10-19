from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("bloom_filter")
fn bloom_filter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 256 or length % 2 != 0 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var queries = 0
    for i in range(Int(length) // 2):
        let op = input[2 * i]; let key = input[2 * i + 1]
        if (op != 1 and op != 2) or key < 0 or key > 1_000_000_000: return -1
        if op == 2: queries += 1
    if queries > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(queries)): return -2
    var bits: UInt64 = 0; var result = List[UInt8](capacity=queries)
    for i in range(Int(length) // 2):
        let op = input[2 * i]; let key = input[2 * i + 1]
        let h1 = Int((17 * key + 3) % 64); let h2 = Int((31 * key + 7) % 64)
        if op == 1: bits = bits | (UInt64(1) << h1) | (UInt64(1) << h2)
        else: result.append(UInt8(1) if ((bits >> h1) & 1) != 0 and ((bits >> h2) & 1) != 0 else UInt8(0))
    for i in range(queries): output[i] = result[i]
    return Int64(queries)
