from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn rmi_less(left: InlineArray[Int, 4], right: InlineArray[Int, 4], n: Int) -> Bool:
    for i in range(n):
        if left[i] != right[i]: return left[i] < right[i]
    return False

@export("rank_maximal_matching_irving")
fn rank_maximal_matching_irving(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 52: return -1
    let a64, p64, e64 = input[0], input[1], input[2]
    if a64 < 1 or a64 > 4 or p64 < 1 or p64 > 4: return -1
    if e64 < a64 or e64 > a64 * p64: return -1
    let applicants, posts, edges = Int(a64), Int(p64), Int(e64)
    if edges > 16 or length != c_size_t(3 + 3 * edges): return -1
    var ranks = InlineArray[Int, 16](fill=0)
    var degree = InlineArray[Int, 4](fill=0)
    var max_rank = 0
    for edge in range(edges):
        let a64 = input[3 + 3 * edge]
        let p64 = input[4 + 3 * edge]
        let r64 = input[5 + 3 * edge]
        if a64 < 0 or a64 >= applicants or p64 < 0 or p64 >= posts or r64 < 1 or r64 > 4: return -1
        let a, p, r = Int(a64), Int(p64), Int(r64)
        let index = a * 4 + p
        if ranks[index] != 0: return -1
        ranks[index] = r
        degree[a] += 1
        if r > max_rank: max_rank = r
    for a in range(applicants):
        if degree[a] == 0: return -1

    var blocked = InlineArray[Bool, 16](fill=False)
    var mate_a = InlineArray[Int, 4](fill=-1)
    var mate_p = InlineArray[Int, 4](fill=-1)
    for phase in range(1, max_rank + 1):
        var limit = 1
        for _ in range(applicants): limit *= posts + 1
        var best = InlineArray[Int, 4](fill=0)
        var best_size = -1
        for code in range(limit):
            var value = code
            var candidate = InlineArray[Int, 4](fill=0)
            var used = 0
            var size = 0
            var valid = True
            for a in range(applicants):
                let p = value % (posts + 1)
                value //= posts + 1
                candidate[a] = p
                if p == posts: continue
                let index = a * 4 + p
                if ranks[index] == 0 or ranks[index] > phase or blocked[index] or used & (1 << p) != 0:
                    valid = False
                    break
                used |= 1 << p
                size += 1
            if valid and (size > best_size or (size == best_size and rmi_less(candidate, best, applicants))):
                best_size = size
                best = candidate
        mate_a = InlineArray[Int, 4](fill=-1)
        mate_p = InlineArray[Int, 4](fill=-1)
        for a in range(applicants):
            if best[a] < posts:
                mate_a[a] = best[a]
                mate_p[best[a]] = a

        var classes = InlineArray[Int, 8](fill=2)
        var queue = InlineArray[Int, 8](fill=0)
        var head, tail = 0, 0
        for a in range(applicants):
            if mate_a[a] < 0:
                classes[a] = 0
                queue[tail] = a
                tail += 1
        for p in range(posts):
            if mate_p[p] < 0:
                let v = applicants + p
                classes[v] = 0
                queue[tail] = v
                tail += 1
        while head < tail:
            let v = queue[head]
            head += 1
            if v < applicants:
                let a = v
                if classes[v] == 0:
                    for p in range(posts):
                        let index = a * 4 + p
                        let w = applicants + p
                        if ranks[index] > 0 and ranks[index] <= phase and not blocked[index] and mate_a[a] != p and classes[w] == 2:
                            classes[w] = 1
                            queue[tail] = w
                            tail += 1
                elif mate_a[a] >= 0:
                    let w = applicants + mate_a[a]
                    if classes[w] == 2:
                        classes[w] = 0
                        queue[tail] = w
                        tail += 1
            else:
                let p = v - applicants
                if classes[v] == 0:
                    for a in range(applicants):
                        let index = a * 4 + p
                        if ranks[index] > 0 and ranks[index] <= phase and not blocked[index] and mate_a[a] != p and classes[a] == 2:
                            classes[a] = 1
                            queue[tail] = a
                            tail += 1
                elif mate_p[p] >= 0:
                    let a = mate_p[p]
                    if classes[a] == 2:
                        classes[a] = 0
                        queue[tail] = a
                        tail += 1

        for a in range(applicants):
            for p in range(posts):
                let index = a * 4 + p
                if ranks[index] == 0 or blocked[index]: continue
                let ca, cp = classes[a], classes[applicants + p]
                if ranks[index] <= phase:
                    if (ca == 1 and cp != 0) or (cp == 1 and ca != 0): blocked[index] = True
                elif ca != 0 or cp != 0:
                    blocked[index] = True

    var signature = InlineArray[Int64, 4](fill=0)
    for a in range(applicants):
        if mate_a[a] >= 0:
            signature[ranks[a * 4 + mate_a[a]] - 1] += 1
    let bytes = 8 * (max_rank + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(max_rank + 1):
        var value: Int64 = Int64(max_rank)
        if word > 0: value = signature[word - 1]
        let bits = bitcast[UInt64](value)
        for byte in range(8): output[8 * word + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
