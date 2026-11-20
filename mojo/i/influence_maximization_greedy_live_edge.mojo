from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn reachable_count(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int,
                   world: Int, seeds: Int) -> Int64:
    var reached = seeds
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 0
    for vertex in range(n):
        if (seeds & (1 << vertex)) != 0:
            queue[tail] = vertex
            tail += 1
    while head < tail:
        let source = queue[head]
        head += 1
        for edge in range(m):
            let offset = 4 + 3 * edge
            let edge_source = Int(input[offset])
            let target = Int(input[offset + 1])
            let target_bit = 1 << target
            if (edge_source == source
                    and (input[offset + 2] & (Int64(1) << world)) != 0
                    and (reached & target_bit) == 0):
                reached |= target_bit
                queue[tail] = target
                tail += 1
    var count: Int64 = 0
    for vertex in range(n):
        if (reached & (1 << vertex)) != 0:
            count += 1
    return count

@export("influence_maximization_greedy_live_edge")
fn influence_maximization_greedy_live_edge(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 77:
        return -1
    let n0 = input[0]
    let m0 = input[1]
    let k0 = input[2]
    let worlds0 = input[3]
    if (n0 < 1 or n0 > 8 or m0 < 0 or m0 > 24 or k0 < 0 or k0 > n0
            or worlds0 < 1 or worlds0 > 8 or length != c_size_t(4 + 3 * m0)):
        return -1
    let n = Int(n0)
    let m = Int(m0)
    let k = Int(k0)
    let worlds = Int(worlds0)
    let allowed = (1 << worlds) - 1
    for edge in range(m):
        let offset = 4 + 3 * edge
        let u = input[offset]
        let v = input[offset + 1]
        let mask = input[offset + 2]
        if (u < 0 or u >= n0 or v < 0 or v >= n0 or u == v
                or mask < 0 or mask > Int64(allowed)):
            return -1
        for earlier in range(edge):
            let prior = 4 + 3 * earlier
            if input[prior] == u and input[prior + 1] == v:
                return -1

    var selected = 0
    var chosen = InlineArray[Int64, 8](fill=0)
    var scores = InlineArray[Int64, 8](fill=0)
    for round in range(k):
        var current = InlineArray[Int64, 8](fill=0)
        for world in range(worlds):
            current[world] = reachable_count(input, n, m, world, selected)
        var best_node = -1
        var best_score: Int64 = -1
        for candidate in range(n):
            let bit = 1 << candidate
            if (selected & bit) != 0:
                continue
            var score: Int64 = 0
            for world in range(worlds):
                score += reachable_count(input, n, m, world, selected | bit) - current[world]
            if score > best_score:
                best_node = candidate
                best_score = score
        if best_node < 0:
            return -1
        selected |= 1 << best_node
        chosen[round] = Int64(best_node)
        scores[round] = best_score

    let bytes = 8 * (1 + 2 * k)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    var words = InlineArray[Int64, 17](fill=0)
    words[0] = Int64(k)
    for round in range(k):
        words[1 + 2 * round] = chosen[round]
        words[2 + 2 * round] = scores[round]
    for word in range(1 + 2 * k):
        var bits = bitcast[UInt64](words[word])
        for byte in range(8):
            output[8 * word + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
