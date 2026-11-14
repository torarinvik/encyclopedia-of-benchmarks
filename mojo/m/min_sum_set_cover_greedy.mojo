# Greedy ordering for bounded min-sum set cover.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("min_sum_set_cover_greedy")
fn min_sum_set_cover_greedy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 18: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 12 or mv < 1 or mv > 16 or length != c_size_t(2+mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var masks = List[Int](capacity=m)
    var covered = List[Bool](capacity=m)
    for i in range(m):
        let mask = input[2+i]
        if mask <= 0 or mask >= Int64(1 << n): return -1
        masks.append(Int(mask))
        covered.append(False)
    var used = List[Bool](capacity=n)
    var order = List[Int64](capacity=n)
    for _ in range(n): used.append(False)
    var total = Int64(0)
    for step in range(n):
        var chosen = -1
        var best = -1
        for element in range(n):
            if used[element]: continue
            var hits = 0
            for set_id in range(m):
                if not covered[set_id] and (masks[set_id] & (1 << element)) != 0: hits += 1
            if hits > best:
                best = hits
                chosen = element
        used[chosen] = True
        order.append(Int64(chosen))
        for set_id in range(m):
            if not covered[set_id] and (masks[set_id] & (1 << chosen)) != 0:
                covered[set_id] = True
                total += Int64(step+1)
    let bytes = 8 * (n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(8): output[byte] = UInt8((total >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((order[i] >> (8*byte)) & 255)
    return Int64(bytes)
