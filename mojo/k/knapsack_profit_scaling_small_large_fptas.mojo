from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("knapsack_profit_scaling_small_large_fptas")
fn knapsack_profit_scaling_small_large_fptas(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 18: return -1
    let cap = input[0]; let n0 = input[1]
    if cap < 1 or cap > 30 or n0 < 1 or n0 > 8 or length != c_size_t(2 + 2 * n0): return -1
    let n = Int(n0)
    var weights = List[Int64](length=n, fill=0)
    var profits = List[Int64](length=n, fill=0)
    var order = List[Int](length=n, fill=0)
    var eligible = 0
    for i in range(n):
        weights[i] = input[2 + 2 * i]; profits[i] = input[3 + 2 * i]
        if weights[i] < 1 or weights[i] > 30 or profits[i] < 1 or profits[i] > 100: return -1
        if weights[i] <= cap:
            order[eligible] = i
            eligible += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    for i in range(1, eligible):
        let key = order[i]
        var j = i
        while j > 0 and profits[key] * weights[order[j - 1]] > profits[order[j - 1]] * weights[key]:
            order[j] = order[j - 1]
            j -= 1
        order[j] = key
    var numerator: Int64 = 0
    var denominator: Int64 = 1
    var room = cap
    for k in range(eligible):
        let i = order[k]
        if weights[i] <= room:
            numerator += profits[i]
            room -= weights[i]
        else:
            numerator = numerator * weights[i] + profits[i] * room
            denominator = weights[i]
            break
    var small = List[Int](length=n, fill=0)
    var large = List[Int](length=n, fill=0)
    var ns = 0; var nl = 0
    for i in range(n):
        if weights[i] <= cap:
            if 4 * profits[i] * denominator <= numerator:
                small[ns] = i
                ns += 1
            else:
                large[nl] = i
                nl += 1
    for i in range(1, ns):
        let key = small[i]
        var j = i
        while j > 0 and profits[key] * weights[small[j - 1]] > profits[small[j - 1]] * weights[key]:
            small[j] = small[j - 1]
            j -= 1
        small[j] = key
    var dpw = List[Int64](length=129, fill=cap + 1)
    var dpm = List[Int64](length=129, fill=0)
    dpw[0] = 0
    var reachable = 0
    for k in range(nl):
        let i = large[k]
        let scaled = Int(16 * profits[i] * denominator // numerator)
        var q = reachable
        while q >= 0:
            if dpw[q] <= cap:
                let dst = q + scaled
                let weight = dpw[q] + weights[i]
                let mask = dpm[q] | (Int64(1) << i)
                if weight < dpw[dst] or (weight == dpw[dst] and mask < dpm[dst]):
                    dpw[dst] = weight
                    dpm[dst] = mask
            q -= 1
        reachable += scaled
    var best_mask: Int64 = 0
    var best_profit: Int64 = 0
    for q in range(reachable + 1):
        if dpw[q] > cap: continue
        var mask = dpm[q]
        var value: Int64 = 0
        var remaining = cap - dpw[q]
        for i in range(n):
            if (mask & (Int64(1) << i)) != 0: value += profits[i]
        for k in range(ns):
            let i = small[k]
            if weights[i] <= remaining:
                remaining -= weights[i]
                mask |= Int64(1) << i
                value += profits[i]
        if value > best_profit or (value == best_profit and mask < best_mask):
            best_profit = value
            best_mask = mask
    for byte in range(8):
        output[byte] = UInt8((best_mask >> (8 * byte)) & 255)
        output[8 + byte] = UInt8((best_profit >> (8 * byte)) & 255)
    return 16
