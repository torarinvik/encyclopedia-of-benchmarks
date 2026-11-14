# Independent bounded Greedy Dual profile; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("greedy_dual_weighted_caching")
fn greedy_dual_weighted_caching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 16: return -1
    let capacity_value = input[0]
    let count_value = input[1]
    if capacity_value < 1 or capacity_value > 8 or count_value < 0 or count_value > 7 or length != c_size_t(2+2*count_value): return -1
    let count = Int(count_value)
    var costs = List[Int64](capacity=8)
    var seen = List[Bool](capacity=8)
    var resident = List[Bool](capacity=8)
    var credit = List[Int64](capacity=8)
    for _ in range(8):
        costs.append(0)
        seen.append(False)
        resident.append(False)
        credit.append(0)
    for i in range(count):
        let id = input[2+2*i]
        let cost = input[3+2*i]
        if id < 0 or id >= 8 or cost < 0 or cost > 20: return -1
        let f = Int(id)
        if seen[f] and costs[f] != cost: return -1
        seen[f] = True
        costs[f] = cost
    var used = 0
    var misses = Int64(0)
    var total = Int64(0)
    var hits = Int64(0)
    var evictions = Int64(0)
    for i in range(count):
        let f = Int(input[2+2*i])
        let cost = input[3+2*i]
        if resident[f]:
            hits |= Int64(1) << i
            credit[f] = cost
            continue
        misses += 1
        total += cost
        var evicted = Int64(0)
        while used >= Int(capacity_value):
            var minimum = Int64(21)
            for j in range(8):
                if resident[j] and credit[j] < minimum: minimum = credit[j]
            for j in range(8):
                if resident[j]:
                    credit[j] -= minimum
                    if credit[j] == 0:
                        resident[j] = False
                        used -= 1
                        evicted |= Int64(1) << j
        evictions |= evicted << (8*i)
        resident[f] = True
        credit[f] = cost
        used += 1
    var mask = Int64(0)
    for i in range(8):
        if resident[i]: mask |= Int64(1) << i
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 40: return -2
    var record = List[Int64](capacity=5)
    record.append(misses); record.append(total); record.append(hits); record.append(evictions); record.append(mask)
    for i in range(5):
        for byte in range(8): output[8*i+byte] = UInt8((record[i] >> (8*byte)) & 255)
    return 40
