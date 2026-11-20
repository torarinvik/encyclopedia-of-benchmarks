from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_i64(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[word * 8 + byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("all_distances_sketch_k_mins")
fn all_distances_sketch_k_mins(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 27: return -1
    let n0 = input[0]
    let assignments0 = input[1]
    if n0 < 1 or n0 > 6 or assignments0 < 1 or assignments0 > 3: return -1
    let n = Int(n0)
    let assignments = Int(assignments0)
    if length != c_size_t(2 + n + assignments * n): return -1

    var distances = List[Int64](capacity=6)
    var ranks = List[Int64](capacity=18)
    var seen = List[Bool](capacity=6)
    var staged = List[Int64](capacity=73)
    for _ in range(6):
        distances.append(0)
        seen.append(False)
    for _ in range(18): ranks.append(0)
    for _ in range(73): staged.append(0)

    for item in range(n):
        let distance = input[2 + item]
        if distance < 0 or distance > 1000000 or (item > 0 and distances[item - 1] >= distance): return -1
        distances[item] = distance
    for assignment in range(assignments):
        for rank in range(n): seen[rank] = False
        for item in range(n):
            let rank = input[2 + n + assignment * n + item]
            if rank < 0 or rank >= n0 or seen[Int(rank)]: return -1
            seen[Int(rank)] = True
            ranks[assignment * 6 + item] = rank

    var count = 0
    for assignment in range(assignments):
        var best_rank = n0
        for item in range(n):
            let rank = ranks[assignment * 6 + item]
            if rank < best_rank:
                staged[1 + 4 * count] = Int64(assignment)
                staged[2 + 4 * count] = Int64(item)
                staged[3 + 4 * count] = rank
                staged[4 + 4 * count] = distances[item]
                count += 1
                best_rank = rank
    staged[0] = Int64(count)
    let words = 1 + 4 * count
    let bytes = 8 * words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(words): put_i64(output, word, staged[word])
    return Int64(bytes)
