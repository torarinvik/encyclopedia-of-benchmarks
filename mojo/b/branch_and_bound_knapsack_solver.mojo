from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bb_bound(weights: List[Int], values: List[Int], count: Int, cap: Int, level: Int, weight: Int, value: Int) -> Float64:
    var remaining = cap - weight; var bound = Float64(value); var next = level + 1
    while remaining > 0 and next < count:
        if weights[next] <= remaining: bound += Float64(values[next]); remaining -= weights[next]
        else: bound += Float64(values[next]) / Float64(weights[next]) * Float64(remaining); remaining = 0
        next += 1
    return bound

@export("branch_and_bound_knapsack_solver")
fn branch_and_bound_knapsack_solver(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 18: return -1
    let nv = input[0]; let capv = input[1]
    if nv < 0 or nv > 8 or capv < 0 or capv > 8000 or length != c_size_t(2 + 2 * nv): return -1
    let n = Int(nv); let cap = Int(capv); var weights = List[Int](capacity=8); var vals = List[Int](capacity=8); var ids = List[Int](capacity=8)
    for _ in range(n): weights.append(0); vals.append(0); ids.append(0)
    for i in range(n):
        let wv = input[2 + 2 * i]; let vv = input[3 + 2 * i]
        if wv < 1 or wv > 1000 or vv < 1 or vv > 1000: return -1
        var pos = i
        while pos > 0 and Int(vv) * weights[pos - 1] > vals[pos - 1] * Int(wv):
            weights[pos] = weights[pos - 1]; vals[pos] = vals[pos - 1]; ids[pos] = ids[pos - 1]; pos -= 1
        weights[pos] = Int(wv); vals[pos] = Int(vv); ids[pos] = i
    var level = List[Int](capacity=511); var weight = List[Int](capacity=511); var value = List[Int](capacity=511); var mask = List[Int](capacity=511)
    level.append(-1); weight.append(0); value.append(0); mask.append(0); var head = 0; var best_value = 0; var best_mask = 0
    while head < len(level):
        let pl = level[head]; let pw = weight[head]; let pv = value[head]; let pm = mask[head]; head += 1
        if pl == n - 1: continue
        let next = pl + 1
        let lw = pw + weights[next]; let lv = pv + vals[next]; let lm = pm | (1 << next)
        if lw <= cap and lv > best_value: best_value = lv; best_mask = lm
        if bb_bound(weights, vals, n, cap, next, lw, lv) > Float64(best_value) and lw < cap:
            level.append(next); weight.append(lw); value.append(lv); mask.append(lm)
        if bb_bound(weights, vals, n, cap, next, pw, pv) > Float64(best_value):
            level.append(next); weight.append(pw); value.append(pv); mask.append(pm)
    var selected = List[UInt8](capacity=8)
    for i in range(n):
        let idx = n - 1 - i
        if (best_mask & (1 << idx)) != 0: selected.append(UInt8(ids[idx]))
    if len(selected) > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(selected))): return -2
    for i in range(len(selected)): output[i] = selected[i]
    return Int64(len(selected))
