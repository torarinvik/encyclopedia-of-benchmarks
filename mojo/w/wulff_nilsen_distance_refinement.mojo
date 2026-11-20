from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias SCALE = 86093442
alias INF = 1152921504606846976
alias MAX_N = 8
alias MAX_INPUT = 93

fn wn_even_index(x: Int, threshold: Int64, nearest: InlineArray[Int32, 32],
                 distance: InlineArray[Int64, 64]) -> Int:
    if distance[x * MAX_N + Int(nearest[2 * MAX_N + x])] <= threshold: return 2
    return 0

fn wn_refine_further(u: Int, v: Int, iu: Int, nearest: InlineArray[Int32, 32],
                     bunch: InlineArray[Bool, 64]) -> Bool:
    if iu < 2: return False
    return (
        bunch[v * MAX_N + Int(nearest[u])] or
        bunch[u * MAX_N + Int(nearest[MAX_N + v])] or
        bunch[v * MAX_N + Int(nearest[iu * MAX_N + u])] or
        bunch[u * MAX_N + Int(nearest[(iu + 1) * MAX_N + v])]
    )

fn wn_impl(input: view[Int64]) -> Int64:
    let length = input.len()
    if length < 8 or length > MAX_INPUT: return -1
    let n0 = input[0]; let m0 = input[1]
    if n0 < 2 or n0 > MAX_N or m0 < 0 or m0 > 28: return -1
    let n = Int(n0); let m = Int(m0)
    if length != 8 + 3 * m: return -1
    let full = (Int64(1) << n) - 1
    var masks = InlineArray[Int64, 3](fill=0)
    for i in range(3):
        masks[i] = input[2 + i]
        if masks[i] <= 0 or (masks[i] & ~full) != 0: return -1
    if (masks[1] & ~masks[0]) != 0 or (masks[2] & ~masks[1]) != 0: return -1

    var distance = InlineArray[Int64, 64](fill=0)
    for u in range(n):
        for v in range(n): distance[u * MAX_N + v] = 0 if u == v else INF
    var prev_u = -1; var prev_v = -1
    for e in range(m):
        let at = 5 + 3 * e
        let u0 = input[at]; let v0 = input[at + 1]; let weight = input[at + 2]
        if u0 < 0 or u0 >= n0 or v0 <= u0 or v0 >= n0 or weight < SCALE or weight > 100 * SCALE or weight % SCALE != 0: return -1
        let u = Int(u0); let v = Int(v0)
        if u < prev_u or (u == prev_u and v <= prev_v): return -1
        prev_u = u; prev_v = v
        distance[u * MAX_N + v] = weight; distance[v * MAX_N + u] = weight
    let q = 5 + 3 * m
    let source0 = input[q]; let target0 = input[q + 1]; let estimate = input[q + 2]
    if source0 < 0 or source0 >= n0 or target0 < 0 or target0 >= n0 or source0 == target0 or estimate <= 0 or estimate % SCALE != 0: return -1
    let source = Int(source0); let target = Int(target0)
    for mid in range(n):
        for u in range(n):
            if distance[u * MAX_N + mid] == INF: continue
            for v in range(n):
                let candidate = distance[u * MAX_N + mid] + distance[mid * MAX_N + v]
                if candidate < distance[u * MAX_N + v]: distance[u * MAX_N + v] = candidate
    for u in range(n):
        for v in range(n):
            if distance[u * MAX_N + v] == INF: return -1
    if estimate < distance[source * MAX_N + target] or estimate > 768 * distance[source * MAX_N + target]: return -1

    var nearest = InlineArray[Int32, 32](fill=0)
    for x in range(n):
        nearest[x] = Int32(x)
        for level in range(1, 4):
            var best = MAX_N
            for y in range(n):
                if ((masks[level - 1] >> y) & 1) != 0 and (best == MAX_N or distance[x * MAX_N + y] < distance[x * MAX_N + best] or (distance[x * MAX_N + y] == distance[x * MAX_N + best] and y < best)):
                    best = y
            nearest[level * MAX_N + x] = Int32(best)
    var layers = InlineArray[Int64, 5](fill=0)
    layers[0] = full; layers[1] = masks[0]; layers[2] = masks[1]; layers[3] = masks[2]
    var bunch = InlineArray[Bool, 64](fill=False)
    for center in range(n):
        for level in range(4):
            var boundary = INF
            for y in range(n):
                if ((layers[level + 1] >> y) & 1) != 0 and distance[center * MAX_N + y] < boundary: boundary = distance[center * MAX_N + y]
            for y in range(n):
                if ((layers[level] >> y) & 1) != 0 and ((layers[level + 1] >> y) & 1) == 0 and distance[center * MAX_N + y] < boundary:
                    bunch[center * MAX_N + y] = True
    var value = estimate
    var iu = wn_even_index(source, value, nearest, distance)
    if not wn_refine_further(source, target, iu, nearest, bunch): return value
    var iteration = 0
    while wn_refine_further(source, target, iu, nearest, bunch) and iteration <= 15:
        value = (2 * value) // 3
        iu = wn_even_index(source, value, nearest, distance)
        iteration += 1
    let upper = wn_even_index(source, (3 * value) // 2, nearest, distance)
    if upper < 2: return -1
    var pivot = Int(nearest[source])
    if bunch[target * MAX_N + pivot]: return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot]
    pivot = Int(nearest[MAX_N + target])
    if bunch[source * MAX_N + pivot]: return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot]
    pivot = Int(nearest[upper * MAX_N + source])
    if bunch[target * MAX_N + pivot]: return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot]
    pivot = Int(nearest[(upper + 1) * MAX_N + target])
    return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot]

@export("wulff_nilsen_distance_refinement")
fn wulff_nilsen_distance_refinement(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > MAX_INPUT: return -1
    let input_view: view[Int64] = input[0:Int(length)]
    wn_impl(input_view)
