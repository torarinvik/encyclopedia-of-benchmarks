from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias K = 16
alias MAX_N = 8
alias MAX_M = 28
alias MAX_Q = 32
alias MAX_INPUT = 167
alias MAX_NODES = 31
alias LOG_K = 4
alias INF = 4611686018427387903

fn wn_put(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

fn wn_mid(low: Int, high: Int) -> Int:
    var chosen = -1
    var best = 2147483647
    for candidate in range(low + 2, high - 1, 2):
        let delta = 2 * candidate - low - high
        let magnitude = if delta < 0: -delta else: delta
        if magnitude < best:
            best = magnitude
            chosen = candidate
    chosen

fn wn_build(source: Int, low: Int, high: Int,
            distance: InlineArray[Int64, 64], nearest: InlineArray[Int32, 128],
            inout counts: InlineArray[Int32, 8],
            inout tree_low: InlineArray[Int32, 248],
            inout tree_high: InlineArray[Int32, 248],
            inout tree_mid: InlineArray[Int32, 248],
            inout tree_gap: InlineArray[Int32, 248],
            inout tree_left: InlineArray[Int32, 248],
            inout tree_right: InlineArray[Int32, 248]) -> Int:
    let local = Int(counts[source])
    if local >= MAX_NODES: return -1
    counts[source] += 1
    let slot = source * MAX_NODES + local
    tree_low[slot] = Int32(low); tree_high[slot] = Int32(high)
    tree_mid[slot] = -1; tree_gap[slot] = -1
    tree_left[slot] = -1; tree_right[slot] = -1
    if high - low <= LOG_K: return local

    let middle = wn_mid(low, high)
    if middle < 0: return -1
    var selected = low
    let near_first = Int(nearest[low * MAX_N + source])
    let far_first = Int(nearest[(low + 2) * MAX_N + source])
    var best_delta = distance[source * MAX_N + far_first] - distance[source * MAX_N + near_first]
    for level in range(low + 2, middle - 1, 2):
        let near = Int(nearest[level * MAX_N + source])
        let far = Int(nearest[(level + 2) * MAX_N + source])
        let delta = distance[source * MAX_N + far] - distance[source * MAX_N + near]
        if delta > best_delta:
            best_delta = delta
            selected = level
    tree_mid[slot] = Int32(middle)
    tree_gap[slot] = Int32(selected)
    let left = wn_build(source, low, selected, distance, nearest, counts,
        tree_low, tree_high, tree_mid, tree_gap, tree_left, tree_right)
    let right = wn_build(source, middle, high, distance, nearest, counts,
        tree_low, tree_high, tree_mid, tree_gap, tree_left, tree_right)
    if left < 0 or right < 0: return -1
    tree_left[slot] = Int32(left); tree_right[slot] = Int32(right)
    local

fn wn_dist_k(source_value: Int, target_value: Int, start: Int,
             distance: InlineArray[Int64, 64], nearest: InlineArray[Int32, 128],
             bunch: InlineArray[Bool, 64], inout probes: Int) -> Int64:
    var source = source_value
    var target = target_value
    var level = start
    while level < K:
        let pivot = Int(nearest[level * MAX_N + source])
        probes += 1
        if bunch[target * MAX_N + pivot]:
            return distance[source * MAX_N + pivot] + distance[target * MAX_N + pivot]
        if level + 1 >= K: return -1
        let old_source = source
        source = target
        target = old_source
        level += 1
    -1

@export("wulff_nilsen_logarithmic_distance_query")
fn wulff_nilsen_logarithmic_distance_query(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 18 or length > MAX_INPUT: return -1
    let n_raw = input[0]
    let m_raw = input[1]
    if n_raw < 1 or n_raw > MAX_N or m_raw < 0 or m_raw > MAX_M: return -1
    let n = Int(n_raw)
    let m = Int(m_raw)
    let valid_bits = (UInt64(1) << n) - 1
    var layers = InlineArray[UInt64, K](fill=0)
    for level in range(1, K):
        let raw = input[1 + level]
        if raw <= 0 or (UInt64(raw) & ~valid_bits) != 0: return -1
        layers[level] = UInt64(raw)
        if level > 1 and (layers[level] & ~layers[level - 1]) != 0: return -1
    let query_at = 17 + 3 * m
    if query_at >= Int(length): return -1
    let q_raw = input[query_at]
    if q_raw < 0 or q_raw > MAX_Q or Int(length) != query_at + 1 + 2 * Int(q_raw): return -1
    let q = Int(q_raw)

    var distance = InlineArray[Int64, 64](fill=INF)
    for vertex in range(n): distance[vertex * MAX_N + vertex] = 0
    var previous_u = -1
    var previous_v = -1
    for edge in range(m):
        let offset = 17 + 3 * edge
        let u_raw = input[offset]
        let v_raw = input[offset + 1]
        let weight = input[offset + 2]
        if u_raw < 0 or v_raw <= u_raw or v_raw >= n or weight < 1 or weight > 1000: return -1
        let u = Int(u_raw); let v = Int(v_raw)
        if u < previous_u or (u == previous_u and v <= previous_v): return -1
        previous_u = u; previous_v = v
        distance[u * MAX_N + v] = weight
        distance[v * MAX_N + u] = weight
    for via in range(n):
        for from_vertex in range(n):
            for to in range(n):
                let candidate = distance[from_vertex * MAX_N + via] + distance[via * MAX_N + to]
                if candidate < distance[from_vertex * MAX_N + to]:
                    distance[from_vertex * MAX_N + to] = candidate
    for from_vertex in range(n):
        for to in range(n):
            if distance[from_vertex * MAX_N + to] == INF: return -1

    var nearest = InlineArray[Int32, 128](fill=0)
    for vertex in range(n): nearest[vertex] = Int32(vertex)
    for level in range(1, K):
        for vertex in range(n):
            var best = -1
            for candidate in range(n):
                if (layers[level] >> candidate) & 1 == 0: continue
                if best < 0:
                    best = candidate
                elif distance[vertex * MAX_N + candidate] < distance[vertex * MAX_N + best] or (distance[vertex * MAX_N + candidate] == distance[vertex * MAX_N + best] and candidate < best):
                    best = candidate
            if best < 0: return -1
            nearest[level * MAX_N + vertex] = Int32(best)

    var bunch = InlineArray[Bool, 64](fill=False)
    for center in range(n):
        for level in range(K):
            let current = if level == 0: valid_bits else: layers[level]
            let following = if level + 1 == K: UInt64(0) else: layers[level + 1]
            var next_distance = INF
            for candidate in range(n):
                if ((following >> candidate) & 1) != 0 and distance[center * MAX_N + candidate] < next_distance:
                    next_distance = distance[center * MAX_N + candidate]
            for candidate in range(n):
                let in_current = ((current >> candidate) & 1) != 0
                let in_next = ((following >> candidate) & 1) != 0
                if in_current and not in_next and distance[center * MAX_N + candidate] < next_distance:
                    bunch[center * MAX_N + candidate] = True

    var tree_low = InlineArray[Int32, 248](fill=0)
    var tree_high = InlineArray[Int32, 248](fill=0)
    var tree_mid = InlineArray[Int32, 248](fill=0)
    var tree_gap = InlineArray[Int32, 248](fill=0)
    var tree_left = InlineArray[Int32, 248](fill=0)
    var tree_right = InlineArray[Int32, 248](fill=0)
    var counts = InlineArray[Int32, 8](fill=0)
    for source in range(n):
        if wn_build(source, 0, K - 1, distance, nearest, counts,
                    tree_low, tree_high, tree_mid, tree_gap, tree_left, tree_right) < 0: return -1

    var staged = InlineArray[Int64, 65](fill=0)
    staged[0] = Int64(q)
    for query in range(q):
        let offset = query_at + 1 + 2 * query
        let source_raw = input[offset]
        let target_raw = input[offset + 1]
        if source_raw < 0 or source_raw >= n or target_raw < 0 or target_raw >= n: return -1
        let source = Int(source_raw); let target = Int(target_raw)
        if source == target:
            staged[1 + 2 * query] = 0
            staged[2 + 2 * query] = 0
            continue
        var node = source * MAX_NODES
        var probes = 0
        while Int(tree_high[node] - tree_low[node]) > LOG_K:
            let gap = Int(tree_gap[node])
            let first = bunch[target * MAX_N + Int(nearest[gap * MAX_N + source])]
            let second = bunch[source * MAX_N + Int(nearest[(gap + 1) * MAX_N + target])]
            probes += 2
            node = source * MAX_NODES + Int(if not first and not second: tree_right[node] else: tree_left[node])
        let estimate = wn_dist_k(source, target, Int(tree_low[node]), distance, nearest, bunch, probes)
        if estimate < 0: return -1
        staged[1 + 2 * query] = estimate
        staged[2 + 2 * query] = Int64(probes)

    let words = 1 + 2 * q
    let bytes = 8 * words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for index in range(words): wn_put(output, 8 * index, staged[index])
    Int64(bytes)
