from std.collections import List
from std.ffi import c_size_t
from std.math import pow
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("truthful_multiunit_ca_greedy2")
fn truthful_multiunit_ca_greedy2(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 32: return -1
    let m0 = input[0]; let n0 = input[1]
    if m0 < 2 or m0 > 6 or n0 < 1 or n0 > 12 or length != c_size_t(2 + m0 + 2 * n0): return -1
    let m = Int(m0); let n = Int(n0)
    var capacities = List[Int64](length=m, fill=0)
    var prices = List[Float64](length=m, fill=0.0)
    var minimum: Int64 = 9
    for i in range(m):
        let value = input[2 + i]
        if value < 1 or value > 8: return -1
        capacities[i] = value
        prices[i] = 1.0 / Float64(value)
        if value < minimum: minimum = value
    var bids = List[Int64](length=n, fill=0)
    var masks = List[Int64](length=n, fill=0)
    for i in range(n):
        bids[i] = input[2 + m + 2 * i]
        masks[i] = input[3 + m + 2 * i]
        if bids[i] < 1 or bids[i] > 100 or masks[i] < 1 or masks[i] >= (Int64(1) << m): return -1
    let threshold = pow(2.718281828459045, Float64(minimum)) * Float64(m)
    var used = List[Bool](length=n, fill=False)
    var order = List[Int64](length=n, fill=0)
    var count = 0
    while count < n:
        var best = -1
        var best_score: Float64 = -1.0
        for i in range(n):
            if used[i]: continue
            var price: Float64 = 0.0
            for e in range(m):
                if (masks[i] & (Int64(1) << e)) != 0: price += prices[e]
            let score = Float64(bids[i]) / price
            if best < 0 or score > best_score:
                best = i
                best_score = score
        if best < 0: break
        used[best] = True
        order[count] = Int64(best)
        count += 1
        for e in range(m):
            if (masks[best] & (Int64(1) << e)) != 0:
                prices[e] *= pow(threshold, 1.0 / Float64(capacities[e]))
        var dual: Float64 = 0.0
        for e in range(m): dual += Float64(capacities[e]) * prices[e]
        if dual >= threshold: break
    let bytes = 8 * (count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(count + 1):
        var value = Int64(count)
        if word > 0: value = order[word - 1]
        for byte in range(8): output[8 * word + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
