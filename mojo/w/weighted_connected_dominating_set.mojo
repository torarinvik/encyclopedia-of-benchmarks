from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("weighted_connected_dominating_set")
fn weighted_connected_dominating_set(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 33: return -1
    let count = input[0]
    if count < 1 or count > 16 or length != c_size_t(1 + 2 * count): return -1
    let n = Int(count)
    let all = (1 << n) - 1
    var adjacency = InlineArray[Int, 16](fill=0)
    var weights = InlineArray[Int64, 16](fill=0)
    for i in range(n):
        let mask = input[1 + i]
        let weight = input[1 + n + i]
        if mask < 0 or mask > Int64(all) or (mask & (Int64(1) << i)) != 0 or weight < 1 or weight > 1000: return -1
        adjacency[i] = Int(mask)
        weights[i] = weight
    for i in range(n):
        for j in range(n):
            if ((adjacency[i] >> j) & 1) != ((adjacency[j] >> i) & 1): return -1
    var best: Int64 = -1
    var best_mask = 0
    for mask in range(1, all + 1):
        var dominated = mask
        var cost: Int64 = 0
        for i in range(n):
            if (mask & (1 << i)) != 0:
                dominated |= adjacency[i]
                cost += weights[i]
        if dominated != all: continue
        var reached = mask & -mask
        while True:
            let old = reached
            for i in range(n):
                if (reached & (1 << i)) != 0: reached |= adjacency[i] & mask
            if reached == old: break
        if reached == mask and (best < 0 or cost < best or (cost == best and mask < best_mask)):
            best = cost
            best_mask = mask
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    for slot in range(2):
        let value = if slot == 0: best else: Int64(best_mask)
        var bits = bitcast[UInt64](value)
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return 16
