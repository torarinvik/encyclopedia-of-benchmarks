# Bounded variable-size Landlord file-cache simulation.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("landlord_file_caching")
fn landlord_file_caching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 23: return -1
    let cache_capacity = input[0]
    let count_value = input[1]
    if cache_capacity < 1 or cache_capacity > 8 or count_value < 0 or count_value > 7 or length != c_size_t(2 + 3*count_value): return -1
    let count = Int(count_value)
    var sizes = List[Int64](capacity=8)
    var costs = List[Int64](capacity=8)
    var credits = List[Int64](capacity=8)
    var seen = List[Bool](capacity=8)
    var resident = List[Bool](capacity=8)
    for _ in range(8):
        sizes.append(0)
        costs.append(0)
        credits.append(0)
        seen.append(False)
        resident.append(False)
    for i in range(count):
        let id = input[2+3*i]
        let size = input[3+3*i]
        let cost = input[4+3*i]
        if id < 0 or id >= 8 or size < 1 or size > 4 or size > cache_capacity or cost < 0 or cost > 20: return -1
        let f = Int(id)
        if seen[f] and (sizes[f] != size or costs[f] != cost): return -1
        seen[f] = True
        sizes[f] = size
        costs[f] = cost
    var used = Int64(0)
    var misses = Int64(0)
    var total = Int64(0)
    var hits = Int64(0)
    var evictions = Int64(0)
    for i in range(count):
        let f = Int(input[2+3*i])
        if resident[f]:
            hits |= Int64(1) << i
            continue
        misses += 1
        total += costs[f]
        var evicted = Int64(0)
        while used + sizes[f] > cache_capacity:
            var delta = Int64(241)
            for j in range(8):
                if resident[j]:
                    let ratio = credits[j] // sizes[j]
                    if ratio < delta: delta = ratio
            for j in range(8):
                if resident[j]:
                    credits[j] -= delta * sizes[j]
                    if credits[j] == 0:
                        resident[j] = False
                        used -= sizes[j]
                        evicted |= Int64(1) << j
        evictions |= evicted << (8*i)
        resident[f] = True
        credits[f] = 12 * costs[f]
        used += sizes[f]
    var mask = Int64(0)
    for i in range(8):
        if resident[i]: mask |= Int64(1) << i
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 40: return -2
    var fields = List[Int64](capacity=5)
    fields.append(misses)
    fields.append(total)
    fields.append(hits)
    fields.append(evictions)
    fields.append(mask)
    for i in range(5):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return 40
