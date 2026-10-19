from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
fn ws(v: Int64) -> Bool: return (v >= 9 and v <= 13) or v == 32

@export("binary_to_base64")
fn binary_to_base64(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 257: return -1
    let nv = input[0]
    if nv < 1 or nv > 256 or length != c_size_t(nv + 1): return -1
    let n = Int(nv)
    for i in range(n):
        if input[1 + i] < 0 or input[1 + i] > 127: return -1
    var begin = 0; var end = n
    while begin < end and ws(input[1 + begin]): begin += 1
    while end > begin and ws(input[end]): end -= 1
    if begin == end: return -1
    let negative = input[1 + begin] == 45
    if negative: begin += 1
    for i in range(begin, end):
        if input[1 + i] != 48 and input[1 + i] != 49: return -1
    let bits = end - begin; let padding = 6 - bits % 6; let groups = (bits + padding) // 6
    let required = groups + (1 if negative else 0)
    if capacity < c_size_t(required) or (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var result = List[UInt8](capacity=required)
    if negative: result.append(45)
    for group in range(groups):
        var value = 0
        for bit in range(6):
            value <<= 1
            let position = group * 6 + bit
            if position >= padding and input[1 + begin + position - padding] == 49: value += 1
        result.append(UInt8(ALPHABET[value]))
    for i in range(required): output[i] = result[i]
    return Int64(required)
