from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("knapsack_profit_scaling_fptas")
fn knapsack_profit_scaling_fptas(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 26: return -1
    let cap = input[0]; let n0 = input[1]
    if cap < 1 or cap > 100 or n0 < 1 or n0 > 12 or length != c_size_t(2 + 2 * n0): return -1
    let n = Int(n0)
    var weights = List[Int64](length=n, fill=0)
    var profits = List[Int64](length=n, fill=0)
    var order = List[Int](length=n, fill=0)
    var eligible = 0
    for i in range(n):
        weights[i] = input[2 + 2 * i]
        profits[i] = input[3 + 2 * i]
        if weights[i] < 1 or weights[i] > 100 or profits[i] < 1 or profits[i] > 10000: return -1
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
    var upper: Int64 = 0
    var room = cap
    for k in range(eligible):
        let i = order[k]
        if weights[i] <= room:
            upper += profits[i]
            room -= weights[i]
        else:
            upper += profits[i] * room // weights[i]
            break
    var dp_weight = List[Int64](length=577, fill=cap + 1)
    var dp_mask = List[Int64](length=577, fill=0)
    dp_weight[0] = 0
    var reachable = 0
    if upper > 0:
        for i in range(n):
            if weights[i] > cap: continue
            let value = Int(4 * n0 * profits[i] // upper)
            if value == 0: continue
            var q = reachable
            while q >= 0:
                if dp_weight[q] <= cap:
                    let next = q + value
                    let weight = dp_weight[q] + weights[i]
                    let mask = dp_mask[q] | (Int64(1) << i)
                    if weight < dp_weight[next] or (weight == dp_weight[next] and mask < dp_mask[next]):
                        dp_weight[next] = weight
                        dp_mask[next] = mask
                q -= 1
            reachable += value
    var best = 0
    for q in range(1, 577):
        if dp_weight[q] <= cap: best = q
    let mask = dp_mask[best]
    var profit: Int64 = 0
    for i in range(n):
        if (mask & (Int64(1) << i)) != 0: profit += profits[i]
    for byte in range(8):
        output[byte] = UInt8((mask >> (8 * byte)) & 255)
        output[8 + byte] = UInt8((profit >> (8 * byte)) & 255)
    return 16
