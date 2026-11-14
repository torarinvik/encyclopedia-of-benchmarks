from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn bit_count(mut value: Int64) -> Int64:
    var count: Int64 = 0
    while value != 0:
        value &= value - 1
        count += 1
    return count

@export("weighted_greedy_set_cover")
fn weighted_greedy_set_cover(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 34: return -1
    let n0 = input[0]
    let m0 = input[1]
    if n0 < 1 or n0 > 16 or m0 < 1 or m0 > 16 or length != c_size_t(2 + 2 * m0): return -1
    let m = Int(m0)
    let full = (Int64(1) << Int(n0)) - 1
    var union: Int64 = 0
    for i in range(m):
        let weight = input[2 + i]
        let mask = input[2 + m + i]
        if weight < 0 or weight > 10000 or mask < 0 or (mask & ~full) != 0: return -1
        union |= mask
    if union != full: return -1
    var covered: Int64 = 0
    var selected = List[Int64](length=m, fill=0)
    var count = 0
    while covered != full:
        var best = -1
        var best_gain: Int64 = 0
        for i in range(m):
            let gain = bit_count(input[2 + m + i] & ~covered)
            if gain == 0: continue
            if best < 0:
                best = i
                best_gain = gain
            elif input[2 + i] * best_gain < input[2 + best] * gain:
                best = i
                best_gain = gain
        if best < 0: return -1
        selected[count] = Int64(best)
        count += 1
        covered |= input[2 + m + best]
    let bytes = 8 * (count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(count + 1):
        var value = Int64(count)
        if word > 0: value = selected[word - 1]
        for byte in range(8): output[8 * word + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
