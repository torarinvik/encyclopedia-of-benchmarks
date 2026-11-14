from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("kkt_mst_sampling_filter")
fn kkt_mst_sampling_filter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 98: return -1
    if input[0] < 2 or input[0] > 12 or input[1] < 1 or input[1] > 24: return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if Int(length) != 2 + 4 * m: return -1
    for i in range(m):
        let at = 2 + 4 * i
        let u = input[at]
        let v = input[at + 1]
        let weight = input[at + 2]
        let sample = input[at + 3]
        if u < 0 or u >= v or v >= Int64(n) or weight < 1 or weight > 1024: return -1
        if sample != 0 and sample != 1: return -1
        for j in range(i):
            let other = 2 + 4 * j
            if (input[other] == u and input[other + 1] == v) or input[other + 2] == weight: return -1
    var order = InlineArray[Int, 24](fill=0)
    for i in range(m): order[i] = i
    for i in range(1, m):
        let edge = order[i]
        var j = i
        while j > 0 and input[4 + 4 * order[j - 1]] > input[4 + 4 * edge]:
            order[j] = order[j - 1]
            j -= 1
        order[j] = edge
    var parent = InlineArray[Int, 12](fill=0)
    for i in range(n): parent[i] = i
    var forest = InlineArray[Bool, 24](fill=False)
    for i in range(m):
        let edge = order[i]
        let at = 2 + 4 * edge
        if input[at + 3] == 0: continue
        var a = Int(input[at])
        var b = Int(input[at + 1])
        while parent[a] != a: a = parent[a]
        while parent[b] != b: b = parent[b]
        if a != b:
            parent[b] = a
            forest[edge] = True
    var result = InlineArray[UInt8, 24](fill=0)
    for edge in range(m):
        if forest[edge]:
            result[edge] = 1
            continue
        let at = 2 + 4 * edge
        let start = Int(input[at])
        let target = Int(input[at + 1])
        var seen = InlineArray[Bool, 12](fill=False)
        var path_max = InlineArray[Int64, 12](fill=0)
        var queue = InlineArray[Int, 12](fill=0)
        var head = 0
        var tail = 1
        seen[start] = True
        queue[0] = start
        while head < tail and not seen[target]:
            let current = queue[head]
            head += 1
            for candidate in range(m):
                if not forest[candidate]: continue
                let pos = 2 + 4 * candidate
                var neighbor = -1
                if input[pos] == Int64(current): neighbor = Int(input[pos + 1])
                elif input[pos + 1] == Int64(current): neighbor = Int(input[pos])
                if neighbor >= 0 and not seen[neighbor]:
                    seen[neighbor] = True
                    path_max[neighbor] = max(path_max[current], input[pos + 2])
                    queue[tail] = neighbor
                    tail += 1
        if not seen[target] or input[at + 2] < path_max[target]: result[edge] = 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(m): return -2
    for i in range(m): output[i] = result[i]
    return Int64(m)
