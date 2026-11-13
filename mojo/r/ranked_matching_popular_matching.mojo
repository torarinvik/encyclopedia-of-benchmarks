from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn rpm_less(left: InlineArray[Int, 4], right: InlineArray[Int, 4], n: Int) -> Bool:
    for i in range(n):
        if left[i] != right[i]: return left[i] < right[i]
    return False

@export("ranked_matching_popular_matching")
fn ranked_matching_popular_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 51: return -1
    let av = input[0]
    let pv = input[1]
    let ev = input[2]
    if av < 1 or av > 4 or pv < 1 or pv > 4: return -1
    if ev < av or ev > av * pv: return -1
    let a_count = Int(av)
    let p_count = Int(pv)
    let edges = Int(ev)
    if length != c_size_t(3 + 3 * edges): return -1
    var ranks = InlineArray[Int, 16](fill=0)
    var max_rank = InlineArray[Int, 4](fill=0)
    var seen = InlineArray[Int, 4](fill=0)
    for e in range(edges):
        let a = input[3 + 3 * e]
        let p = input[4 + 3 * e]
        let r = input[5 + 3 * e]
        if a < 0 or a >= av or p < 0 or p >= pv or r < 1 or r > pv: return -1
        let ai = Int(a)
        let pi = Int(p)
        let ri = Int(r)
        if ranks[ai * 4 + pi] != 0: return -1
        ranks[ai * 4 + pi] = ri
        seen[ai] |= 1 << ri
        if ri > max_rank[ai]: max_rank[ai] = ri
    for a in range(a_count):
        if max_rank[a] == 0: return -1
        for r in range(1, max_rank[a] + 1):
            if seen[a] & (1 << r) == 0: return -1

    var limit = 1
    for _ in range(a_count): limit *= p_count + 1
    var best_first = InlineArray[Int, 4](fill=0)
    var first_size = -1
    for code in range(limit):
        var value = code
        var candidate = InlineArray[Int, 4](fill=0)
        var used = 0
        var count = 0
        var valid = True
        for a in range(a_count):
            let p = value % (p_count + 1)
            value //= p_count + 1
            candidate[a] = p
            if p == p_count: continue
            if ranks[a * 4 + p] != 1 or used & (1 << p) != 0:
                valid = False
                break
            used |= 1 << p
            count += 1
        if valid and (count > first_size or (count == first_size and rpm_less(candidate, best_first, a_count))):
            first_size = count
            best_first = candidate

    var mate_a = InlineArray[Int, 4](fill=-1)
    var mate_p = InlineArray[Int, 4](fill=-1)
    for a in range(a_count):
        let p = best_first[a]
        if p < p_count:
            mate_a[a] = p
            mate_p[p] = a
    let total_posts = p_count + a_count
    let nodes = a_count + total_posts
    var parity = InlineArray[Int, 12](fill=-1)
    var queue = InlineArray[Int, 12](fill=0)
    var head = 0
    var tail = 0
    for a in range(a_count):
        if mate_a[a] < 0:
            parity[a] = 0
            queue[tail] = a
            tail += 1
    for p in range(total_posts):
        var exposed = p >= p_count
        if p < p_count: exposed = mate_p[p] < 0
        if exposed:
            let node = a_count + p
            parity[node] = 0
            queue[tail] = node
            tail += 1
    while head < tail:
        let node = queue[head]
        head += 1
        if node < a_count:
            let a = node
            if parity[node] == 0:
                for p in range(p_count):
                    let target = a_count + p
                    if ranks[a * 4 + p] == 1 and mate_a[a] != p and parity[target] < 0:
                        parity[target] = 1
                        queue[tail] = target
                        tail += 1
            elif mate_a[a] >= 0:
                let target = a_count + mate_a[a]
                if parity[target] < 0:
                    parity[target] = 0
                    queue[tail] = target
                    tail += 1
        else:
            let p = node - a_count
            if p < p_count:
                if parity[node] == 0:
                    for a in range(a_count):
                        if ranks[a * 4 + p] == 1 and mate_a[a] != p and parity[a] < 0:
                            parity[a] = 1
                            queue[tail] = a
                            tail += 1
                elif mate_p[p] >= 0:
                    let target = mate_p[p]
                    if parity[target] < 0:
                        parity[target] = 0
                        queue[tail] = target
                        tail += 1
    for node in range(nodes):
        if parity[node] < 0: parity[node] = 2
    var allowed = InlineArray[Bool, 32](fill=False)
    for a in range(a_count):
        var best_even_rank = p_count + 1
        for p in range(p_count):
            let r = ranks[a * 4 + p]
            if r > 0 and parity[a_count + p] == 0 and r < best_even_rank: best_even_rank = r
        let last_rank = max_rank[a] + 1
        if last_rank < best_even_rank: best_even_rank = last_rank
        for p in range(total_posts):
            var reduced = False
            if p < p_count:
                let r = ranks[a * 4 + p]
                reduced = r == 1 or (r > 0 and r == best_even_rank and parity[a_count + p] == 0)
            elif p == p_count + a:
                reduced = last_rank == best_even_rank
            let ca = parity[a]
            let cp = parity[a_count + p]
            if reduced and not ((ca == 1 and (cp == 1 or cp == 2)) or (ca == 2 and cp == 1)):
                allowed[a * 8 + p] = True

    var full_limit = 1
    for _ in range(a_count): full_limit *= total_posts
    var found = False
    var best = InlineArray[Int, 4](fill=-1)
    for code in range(full_limit):
        var value = code
        var candidate = InlineArray[Int, 4](fill=0)
        var used = 0
        var count = 0
        var valid = True
        for a in range(a_count):
            let p = value % total_posts
            value //= total_posts
            candidate[a] = p
            if not allowed[a * 8 + p] or used & (1 << p) != 0:
                valid = False
                break
            used |= 1 << p
            if p < p_count and ranks[a * 4 + p] == 1: count += 1
        if valid and count == first_size and (not found or rpm_less(candidate, best, a_count)):
            found = True
            best = candidate
    let bytes = 8 * (a_count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(a_count + 1):
        var value: Int64 = -1
        if word == 0: value = 1 if found else 0
        elif found: value = Int64(best[word - 1])
        let bits = bitcast[UInt64](value)
        for byte in range(8): output[8 * word + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
