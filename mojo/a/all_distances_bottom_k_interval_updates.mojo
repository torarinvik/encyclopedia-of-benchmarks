from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_i64(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[word * 8 + byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("all_distances_bottom_k_interval_updates")
fn all_distances_bottom_k_interval_updates(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 99: return -1
    let n0 = input[0]
    let k0 = input[1]
    if n0 < 2 or n0 > 32 or k0 < 2 or k0 > 4 or k0 > n0: return -1
    let n = Int(n0)
    let k = Int(k0)
    if length != c_size_t(2 + 3 * n): return -1

    var ids = List[Int64](capacity=32)
    var distances = List[Int64](capacity=32)
    var ranks = List[Int64](capacity=32)
    var seen_id = List[Bool](capacity=32)
    var seen_rank = List[Bool](capacity=32)
    for _ in range(32):
        ids.append(0); distances.append(0); ranks.append(0)
        seen_id.append(False); seen_rank.append(False)
    for i in range(n):
        let id = input[2 + 3 * i]
        let distance = input[3 + 3 * i]
        let rank = input[4 + 3 * i]
        if id < 0 or id >= n0 or seen_id[Int(id)] or rank < 0 or rank >= n0
                or seen_rank[Int(rank)] or distance < 0 or distance > 1000000: return -1
        ids[Int(i)] = id
        distances[Int(i)] = distance
        ranks[Int(i)] = rank
        seen_id[Int(id)] = True
        seen_rank[Int(rank)] = True
        for j in range(i):
            if distances[j] == distance: return -1
    for i in range(1, k):
        if distances[i - 1] >= distances[i]: return -1
    for i in range(k, n):
        if distances[i] <= distances[k - 1]: return -1

    # Flat four-word interval records: ID, rank, start, end.
    var intervals = List[Int64](capacity=128)
    for _ in range(128): intervals.append(0)
    var count = k
    for i in range(k):
        intervals[4 * i] = ids[i]
        intervals[4 * i + 1] = ranks[i]
        intervals[4 * i + 2] = distances[i]
        intervals[4 * i + 3] = 1000001
    for i in range(k, n):
        var worst = 32
        var active = 0
        for j in range(count):
            let base = 4 * j
            if intervals[base + 2] <= distances[i] and distances[i] < intervals[base + 3]:
                active += 1
                if worst == 32 or intervals[base + 1] > intervals[4 * worst + 1]: worst = j
        if active != k or worst == 32: return -1
        if ranks[i] >= intervals[4 * worst + 1]: continue
        var cursor = intervals[4 * worst + 3]
        intervals[4 * worst + 3] = distances[i]
        while cursor < 1000001:
            var next_worst = 32
            for j in range(count):
                let base = 4 * j
                if intervals[base + 2] <= cursor and cursor < intervals[base + 3]
                        and (next_worst == 32 or intervals[base + 1] > intervals[4 * next_worst + 1]):
                    next_worst = j
            if next_worst == 32 or intervals[4 * next_worst + 1] <= ranks[i]: break
            let next_cursor = intervals[4 * next_worst + 3]
            intervals[4 * next_worst + 3] = cursor
            cursor = next_cursor
        intervals[4 * count] = ids[i]
        intervals[4 * count + 1] = ranks[i]
        intervals[4 * count + 2] = distances[i]
        intervals[4 * count + 3] = cursor
        count += 1

    var order = List[Int](capacity=32)
    for _ in range(32): order.append(0)
    var out_count = 0
    for i in range(count):
        if intervals[4 * i + 2] < intervals[4 * i + 3]:
            order[out_count] = i
            out_count += 1
    for i in range(1, out_count):
        let key = order[i]
        var j = i
        while j > 0 and (intervals[4 * order[j - 1] + 2] > intervals[4 * key + 2]
                or (intervals[4 * order[j - 1] + 2] == intervals[4 * key + 2]
                    and intervals[4 * order[j - 1]] > intervals[4 * key])):
            order[j] = order[j - 1]
            j -= 1
        order[j] = key

    var staged = List[Int64](capacity=97)
    for _ in range(97): staged.append(0)
    staged[0] = Int64(out_count)
    for i in range(out_count):
        let base = 4 * order[i]
        staged[1 + 3 * i] = intervals[base]
        staged[2 + 3 * i] = intervals[base + 2]
        staged[3 + 3 * i] = intervals[base + 3]
    let words = 1 + 3 * out_count
    let bytes = 8 * words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(words): put_i64(output, word, staged[word])
    return Int64(bytes)
