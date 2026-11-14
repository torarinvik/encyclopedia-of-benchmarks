# Clean-room bounded streamcluster pgain profile; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("rodinia_streamcluster_pgain")
fn rodinia_streamcluster_pgain(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 53: return -1
    if input[0] < 2 or input[0] > 8 or input[1] < 1 or input[1] > 3: return -1
    let n = Int(input[0]); let dim = Int(input[1]); let raw_candidate = input[2]
    let fee = input[3]; let mask = input[4]
    if length != c_size_t(5+n*(3+dim)) or raw_candidate < 0 or raw_candidate >= Int64(n) or fee < 1 or fee > 64 or mask <= 0 or mask >= Int64(1 << n): return -1
    let candidate = Int(raw_candidate)
    if (mask & (Int64(1) << candidate)) != 0: return -1
    var assignments = InlineArray[Int, 8](fill=0)
    var weights = InlineArray[Int64, 8](fill=0)
    var costs = InlineArray[Int64, 8](fill=0)
    var points = InlineArray[Int64, 24](fill=0)
    var cursor = 5
    for i in range(n):
        if input[cursor] < 0 or input[cursor] >= Int64(n): return -1
        assignments[i] = Int(input[cursor]); cursor += 1
        if (mask & (Int64(1) << assignments[i])) == 0: return -1
    for i in range(n):
        if input[cursor] < 1 or input[cursor] > 4: return -1
        weights[i] = input[cursor]; cursor += 1
    for i in range(n): costs[i] = input[cursor]; cursor += 1
    for i in range(n):
        for axis in range(dim):
            let value = input[cursor]; cursor += 1
            if value < -8 or value > 8: return -1
            points[3*i+axis] = value
    for i in range(n):
        var distance: Int64 = 0
        for axis in range(dim):
            let delta = points[3*i+axis]-points[3*assignments[i]+axis]
            distance += delta*delta
        if costs[i] != weights[i]*distance: return -1
        if (mask & (Int64(1) << i)) != 0 and (assignments[i] != i or costs[i] != 0): return -1
    var switched = InlineArray[Bool, 8](fill=False)
    var closing = InlineArray[Bool, 8](fill=False)
    var lower = InlineArray[Int64, 8](fill=0)
    var proposed = InlineArray[Int64, 8](fill=0)
    var opening = fee
    for i in range(n):
        var distance: Int64 = 0
        for axis in range(dim):
            let delta = points[3*i+axis]-points[3*candidate+axis]
            distance += delta*delta
        proposed[i] = weights[i]*distance
        if proposed[i] < costs[i]:
            switched[i] = True; opening += proposed[i]-costs[i]
        else: lower[assignments[i]] += costs[i]-proposed[i]
    for center in range(n):
        if (mask & (Int64(1) << center)) != 0 and fee+lower[center] > 0:
            closing[center] = True; opening -= fee+lower[center]
    let opened = opening < 0
    var result_mask = mask
    if opened:
        for i in range(n):
            if switched[i] or closing[assignments[i]]:
                assignments[i] = candidate; costs[i] = proposed[i]
        for i in range(n):
            if closing[i]: result_mask &= ~(Int64(1) << i)
        result_mask |= Int64(1) << candidate
    var center_count: Int64 = 0; var objective: Int64 = 0
    for i in range(n):
        if (result_mask & (Int64(1) << i)) != 0: center_count += 1
        objective += costs[i]
    objective += center_count*fee
    let words_count = 5+2*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*words_count): return -2
    var words = InlineArray[Int64, 21](fill=0)
    if opened: words[0] = 1; words[1] = -opening
    words[2] = center_count; words[3] = result_mask; words[4] = objective
    for i in range(n): words[5+i] = Int64(assignments[i]); words[5+n+i] = costs[i]
    for i in range(words_count):
        let bits = UInt64(words[i])
        for b in range(8): output[8*i+b] = UInt8((bits >> (8*b)) & 255)
    return Int64(words_count)
