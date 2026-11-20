from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("shannon_fano_elias_symbol_codes")
fn shannon_fano_elias_symbol_codes(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 10:
        return -1
    let values = input[0:length]
    let raw_n = values[0]
    if raw_n < 1 or raw_n > 8 or length != c_size_t(raw_n + 1):
        return -1
    let n = Int(raw_n)
    var total: Int64 = 0
    for i in range(n):
        let weight = values[1 + i]
        if weight < 1 or weight > 15: return -1
        total += weight
    if total > 120: return -1

    var staged = List[UInt8](length=17, fill=0)
    staged[0] = UInt8(n)
    var prefix: Int64 = 0
    for i in range(n):
        let weight = values[1 + i]
        var bits = 1
        while (Int64(1) << (bits - 1)) * weight < total: bits += 1
        let numerator = (2 * prefix + weight) * (Int64(1) << (bits - 1))
        let code = UInt8(numerator / total)
        staged[1 + 2 * i] = UInt8(bits)
        staged[2 + 2 * i] = code << (8 - bits)
        prefix += weight
    let needed = 1 + 2 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed):
        return -2
    for i in range(needed): output[i] = staged[i]
    Int64(needed)
