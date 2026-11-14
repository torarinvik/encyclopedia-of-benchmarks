from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("stochastic_knapsack_greedy")
fn stochastic_knapsack_greedy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 43: return -1
    if input[0] < 1 or input[0] > 5 or input[1] < 1 or input[1] > 8: return -1
    let n = Int(input[0])
    let bound = input[1]
    let end = Int(length)
    var rewards = InlineArray[Int64, 5](fill=0)
    var counts = InlineArray[Int, 5](fill=0)
    var denominator = InlineArray[Int64, 5](fill=0)
    var fit = InlineArray[Int64, 5](fill=0)
    var mean = InlineArray[Int64, 5](fill=0)
    var sizes = InlineArray[Int64, 15](fill=0)
    var weights = InlineArray[Int64, 15](fill=0)
    var cursor = 2
    for item in range(n):
        if cursor + 2 > end: return -1
        let reward = input[cursor]
        let atoms = input[cursor + 1]
        cursor += 2
        if reward < 0 or reward > 20 or atoms < 1 or atoms > 3: return -1
        rewards[item] = reward
        counts[item] = Int(atoms)
        for atom in range(Int(atoms)):
            if cursor + 2 > end: return -1
            let size = input[cursor]
            let weight = input[cursor + 1]
            cursor += 2
            if size < 0 or size > bound + 1 or weight < 1 or weight > 3: return -1
            sizes[item * 3 + atom] = size
            weights[item * 3 + atom] = weight
            denominator[item] += weight
            if size <= bound: fit[item] += weight
            mean[item] += min(size, bound) * weight
        if denominator[item] > 9 or mean[item] == 0: return -1
    if cursor != end: return -1
    var order = InlineArray[Int, 5](fill=0)
    for item in range(n):
        var j = item
        while j > 0:
            let prior = order[j - 1]
            let left = rewards[item] * fit[item] * mean[prior]
            let right = rewards[prior] * fit[prior] * mean[item]
            if left <= right: break
            order[j] = prior
            j -= 1
        order[j] = item
    var best = 0
    for item in range(1, n):
        if rewards[item] * fit[item] * denominator[best] > rewards[best] * fit[best] * denominator[item]: best = item
    var joint: Int64 = 1
    var scenarios = 1
    for i in range(n):
        joint *= denominator[i]
        scenarios *= counts[i]
    var single_score: Int64 = 0
    var order_score: Int64 = 0
    for scenario in range(scenarios):
        var digits = scenario
        var probability_weight: Int64 = 1
        var chosen = InlineArray[Int64, 5](fill=0)
        for item in range(n):
            let atom = digits % counts[item]
            digits //= counts[item]
            chosen[item] = sizes[item * 3 + atom]
            probability_weight *= weights[item * 3 + atom]
        if chosen[best] <= bound: single_score += probability_weight * rewards[best]
        var used: Int64 = 0
        var earned: Int64 = 0
        for rank in range(n):
            let item = order[rank]
            if used + chosen[item] > bound: break
            used += chosen[item]
            earned += rewards[item]
        order_score += probability_weight * earned
    let use_order = order_score > single_score
    let output_count = if use_order: n else: 1
    var words = InlineArray[Int64, 9](fill=0)
    if use_order: words[0] = 1
    words[1] = Int64(output_count)
    for i in range(output_count):
        words[2 + i] = if use_order: Int64(order[i]) else: Int64(best)
    words[2 + output_count] = if use_order: order_score else: single_score
    words[3 + output_count] = joint
    let bytes = (output_count + 4) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(output_count + 4):
        var bits = UInt64(words[i])
        for b in range(8):
            output[8 * i + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
