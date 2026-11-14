from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn rumor_infected(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int, edge_base: Int,
                  world: Int, sources: Int, protectors: Int) -> Int64:
    var rumor = sources
    var protected = protectors
    var rumor_front = sources
    var protect_front = protectors
    for _ in range(n):
        var new_rumor = 0
        var new_protect = 0
        let occupied = rumor | protected
        for e in range(m):
            let at = edge_base + 3 * e
            let source = Int(input[at])
            let target = Int(input[at + 1])
            let target_bit = 1 << target
            if (occupied & target_bit) != 0: continue
            if (protect_front & (1 << source)) != 0: new_protect |= target_bit
            if (rumor_front & (1 << source)) != 0 and (input[at + 2] & (Int64(1) << world)) != 0: new_rumor |= target_bit
        new_rumor &= ~new_protect
        if new_rumor == 0 and new_protect == 0: break
        rumor |= new_rumor
        protected |= new_protect
        rumor_front = new_rumor
        protect_front = new_protect
    var total: Int64 = 0
    for v in range(n):
        if (rumor & (1 << v)) != 0: total += 1
    return total

@export("rumor_blocking_greedy_live_edge")
fn rumor_blocking_greedy_live_edge(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 61: return -1
    if input[0] < 2 or input[0] > 8 or input[1] < 0 or input[1] > 16: return -1
    if input[2] < 1 or input[2] >= input[0] or input[3] < 1 or input[3] > 3: return -1
    if input[3] > input[0] - input[2] or input[4] < 1 or input[4] > 8: return -1
    let n = Int(input[0])
    let m = Int(input[1])
    let r = Int(input[2])
    let k = Int(input[3])
    let worlds = Int(input[4])
    if Int(length) != 5 + r + 3 * m: return -1
    var sources = 0
    for i in range(r):
        let vertex = input[5 + i]
        if vertex < 0 or vertex >= Int64(n): return -1
        let bit = 1 << Int(vertex)
        if (sources & bit) != 0: return -1
        sources |= bit
    let edge_base = 5 + r
    for e in range(m):
        let at = edge_base + 3 * e
        let u = input[at]
        let v = input[at + 1]
        let mask = input[at + 2]
        if u < 0 or u >= Int64(n) or v < 0 or v >= Int64(n) or u == v: return -1
        if mask < 0 or mask >= Int64(1 << worlds): return -1
        for earlier in range(e):
            let prior = edge_base + 3 * earlier
            if input[prior] == u and input[prior + 1] == v: return -1
    var words = InlineArray[Int64, 7](fill=0)
    words[0] = Int64(k)
    var baseline = InlineArray[Int64, 8](fill=0)
    for world in range(worlds):
        baseline[world] = rumor_infected(input, n, m, edge_base, world, sources, 0)
    var selected = 0
    for round in range(k):
        var current_saved = InlineArray[Int64, 8](fill=0)
        for world in range(worlds):
            current_saved[world] = baseline[world] - rumor_infected(input, n, m, edge_base, world, sources, selected)
        var best_node = -1
        var best_score: Int64 = -9223372036854775807
        for candidate in range(n):
            let bit = 1 << candidate
            if ((sources | selected) & bit) != 0: continue
            var score: Int64 = 0
            for world in range(worlds):
                let updated = rumor_infected(input, n, m, edge_base, world, sources, selected | bit)
                score += baseline[world] - updated - current_saved[world]
            if best_node < 0 or score > best_score:
                best_node = candidate
                best_score = score
        if best_node < 0: return -1
        selected |= 1 << best_node
        words[1 + 2 * round] = Int64(best_node)
        words[2 + 2 * round] = best_score
    let bytes = 8 * (1 + 2 * k)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(1 + 2 * k):
        var bits = bitcast[UInt64](words[i])
        for b in range(8):
            output[8 * i + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
