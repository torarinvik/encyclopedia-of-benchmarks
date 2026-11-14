# Independent bounded GBBS set-cover profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn population(mask: Int) -> Int:
    var bits = mask
    var count = 0
    while bits != 0:
        bits &= bits-1
        count += 1
    return count

@export("gbbs_approximate_set_cover")
fn gbbs_approximate_set_cover(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 10: return -1
    let nv = input[0]
    if nv < 1 or nv > 8 or length != c_size_t(nv+1): return -1
    let n = Int(nv)
    let valid = (1 << n)-1
    var sets = List[Int](capacity=n)
    var bucket = List[Int](capacity=n)
    for s in range(n):
        let value = input[1+s]
        if value < 0 or value > Int64(valid): return -1
        let mask = Int(value)
        if (mask & (1 << s)) != 0: return -1
        sets.append(mask)
        bucket.append(population(mask))
    for u in range(n):
        for v in range(n):
            if ((sets[u] >> v) & 1) != ((sets[v] >> u) & 1): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var uncovered = valid
    var selected = 0
    var round = 0
    while uncovered != 0:
        var top = 0
        for s in range(n):
            if bucket[s] > top: top = bucket[s]
        if top == 0: break
        var eligible = List[Bool](capacity=n)
        var wins = List[Int](capacity=n)
        var eligible_count = 0
        for s in range(n):
            var yes = False
            if bucket[s] == top:
                bucket[s] = population(sets[s] & uncovered)
                yes = bucket[s] >= top
                if yes: eligible_count += 1
            eligible.append(yes)
            wins.append(0)
        for e in range(n):
            let bit = 1 << e
            if (uncovered & bit) == 0: continue
            for r in range(n):
                let s = (round+r) % n
                if eligible[s] and (sets[s] & bit) != 0:
                    wins[s] += 1
                    break
        var chosen = 0
        for s in range(n):
            if eligible[s] and wins[s] >= top: chosen |= 1 << s
        if chosen == 0 and eligible_count != 0: return -1
        selected |= chosen
        var covered = 0
        for s in range(n):
            if (chosen & (1 << s)) != 0:
                covered |= sets[s]
                bucket[s] = 0
        uncovered &= ~covered
        round += 1
    let first = Int64(selected)
    let second = Int64(uncovered)
    for byte in range(8):
        output[byte] = UInt8((first >> (8*byte)) & 255)
        output[8+byte] = UInt8((second >> (8*byte)) & 255)
    return 16
