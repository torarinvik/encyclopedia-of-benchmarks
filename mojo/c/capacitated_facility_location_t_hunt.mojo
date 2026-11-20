from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 4
comptime MAX_F = 3
comptime MAX_Q = 4
comptime MAX_P = 7
comptime NEG_INF = -2305843009213693952

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & 255)

fn solve_profile(n: Int, f: Int, q: Int, target: Int, distances: List[Int64],
                 fees: List[Int64], capacities: List[Int64], kinds: List[Int],
                 assignments: List[Int]) -> List[Int64]:
    let points = n + f
    var weights = List[Int64](capacity=q)
    var profits = List[Int64](capacity=q)
    var old_cost = Int64(0)
    for copy in range(q):
        weights.append(0)
        profits.append(fees[kinds[copy]])
        old_cost += fees[kinds[copy]]
    for client in range(n):
        let copy = assignments[client]
        let before = distances[client * points + n + kinds[copy]]
        let after = distances[client * points + n + target]
        weights[copy] += 1
        old_cost += before
        profits[copy] -= after - before
    var result = List[Int64](capacity=5)
    result.append(0)
    result.append(0)
    result.append(0)
    result.append(old_cost)
    result.append(old_cost)
    for copies in range(1, n + 1):
        let limit = min(n, copies * Int(capacities[target]))
        var dp = List[Int64](capacity=limit + 1)
        var masks = List[UInt32](capacity=limit + 1)
        for weight in range(limit + 1):
            dp.append(NEG_INF)
            masks.append(0)
        dp[0] = 0
        for item in range(q):
            var next = List[Int64](capacity=limit + 1)
            var next_masks = List[UInt32](capacity=limit + 1)
            for weight in range(limit + 1):
                next.append(dp[weight])
                next_masks.append(masks[weight])
            let item_weight = Int(weights[item])
            if item_weight <= limit:
                for used in range(limit - item_weight + 1):
                    if dp[used] != NEG_INF:
                        let new_weight = used + item_weight
                        let value = dp[used] + profits[item]
                        let mask = masks[used] | (UInt32(1) << UInt32(item))
                        if value > next[new_weight] or (value == next[new_weight] and mask < next_masks[new_weight]):
                            next[new_weight] = value
                            next_masks[new_weight] = mask
            dp = next
            masks = next_masks
        var best_profit = NEG_INF
        var best_mask = UInt32(0)
        for weight in range(limit + 1):
            if dp[weight] > best_profit or (dp[weight] == best_profit and masks[weight] < best_mask):
                best_profit = dp[weight]
                best_mask = masks[weight]
        if best_profit > Int64(copies) * fees[target]:
            result[0] = 1
            result[1] = Int64(copies)
            result[2] = Int64(best_mask)
            result[4] = old_cost + Int64(copies) * fees[target] - best_profit
            break
    return result

@export("capacitated_facility_location_t_hunt")
fn capacitated_facility_location_t_hunt(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 68:
        return -1
    let nr, fr, qr, tr = input[0], input[1], input[2], input[3]
    if nr < 1 or nr > MAX_N or fr < 1 or fr > MAX_F or qr < 1 or qr > MAX_Q or tr < 0 or tr >= fr:
        return -1
    let n, f, q, target = Int(nr), Int(fr), Int(qr), Int(tr)
    let points = n + f
    if length != c_size_t(4 + points * points + 2 * f + q + n):
        return -1
    var distances = List[Int64](capacity=points * points)
    for cell in range(points * points):
        let value = input[4 + cell]
        if value < 0 or value > 1000: return -1
        distances.append(value)
    for i in range(points):
        if distances[i * points + i] != 0: return -1
        for j in range(points):
            let value = distances[i * points + j]
            if i != j and value == 0: return -1
            if value != distances[j * points + i]: return -1
            for k in range(points):
                if value > distances[i * points + k] + distances[k * points + j]: return -1
    var at = 4 + points * points
    var fees = List[Int64](capacity=f)
    var capacities = List[Int64](capacity=f)
    var kinds = List[Int](capacity=q)
    var assignments = List[Int](capacity=n)
    for i in range(f):
        let value = input[at]
        at += 1
        if value < 0 or value > 1000: return -1
        fees.append(value)
    for i in range(f):
        let value = input[at]
        at += 1
        if value < 1 or value > nr: return -1
        capacities.append(value)
    for i in range(q):
        let value = input[at]
        at += 1
        if value < 0 or value >= fr: return -1
        kinds.append(Int(value))
    for i in range(n):
        let value = input[at]
        at += 1
        if value < 0 or value >= qr: return -1
        assignments.append(Int(value))
    var loads = List[Int](capacity=q)
    for copy in range(q): loads.append(0)
    for client in range(n): loads[assignments[client]] += 1
    for copy in range(q):
        if loads[copy] > Int(capacities[kinds[copy]]): return -1
    let result = solve_profile(n, f, q, target, distances, fees, capacities, kinds, assignments)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 40: return -2
    for word in range(5): put_word(output, word * 8, result[word])
    return 40
