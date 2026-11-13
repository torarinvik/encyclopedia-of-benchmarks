from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("approximate_matching_greedy")
fn approximate_matching_greedy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 98: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 12 or mv < 0 or mv > 32 or length != c_size_t(2 + 3 * mv): return -1
    let m = Int(mv)
    var left = InlineArray[Int, 32](fill=0)
    var right = InlineArray[Int, 32](fill=0)
    var weights = InlineArray[Int64, 32](fill=0)
    var seen = InlineArray[Bool, 144](fill=False)
    for edge in range(m):
        let u = input[2 + 3 * edge]
        let v = input[3 + 3 * edge]
        let weight = input[4 + 3 * edge]
        if u < 0 or u >= nv or v < 0 or v >= nv or u == v or weight < 1 or weight > 100: return -1
        let lo = Int(min(u, v))
        let hi = Int(max(u, v))
        if seen[lo * 12 + hi]: return -1
        seen[lo * 12 + hi] = True
        left[edge] = Int(u)
        right[edge] = Int(v)
        weights[edge] = weight
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var used = InlineArray[Bool, 32](fill=False)
    var matched = InlineArray[Bool, 12](fill=False)
    var total: Int64 = 0
    var mask: UInt64 = 0
    for _ in range(m):
        var best = -1
        for edge in range(m):
            if not used[edge] and (best < 0 or weights[edge] > weights[best]): best = edge
        used[best] = True
        let u = left[best]
        let v = right[best]
        if not matched[u] and not matched[v]:
            matched[u] = True
            matched[v] = True
            total += weights[best]
            mask |= UInt64(1) << UInt(best)
    let total_bits = UInt64(total)
    for byte in range(8):
        output[byte] = UInt8((total_bits >> UInt(8 * byte)) & 255)
        output[8 + byte] = UInt8((mask >> UInt(8 * byte)) & 255)
    return 16
