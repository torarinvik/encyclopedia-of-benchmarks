from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("frt_tree_metric")
fn frt_tree_metric(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 74: return -1
    if input[0] < 2 or input[0] > 8 or input[1] < 1024 or input[1] > 2047: return -1
    let n = Int(input[0])
    let beta = input[1]
    if Int(length) != 2 + n + n * n: return -1
    var permutation = InlineArray[Int, 8](fill=0)
    var seen = InlineArray[Bool, 8](fill=False)
    for i in range(n):
        let p = input[2 + i]
        if p < 0 or p >= Int64(n): return -1
        if seen[Int(p)]: return -1
        seen[Int(p)] = True
        permutation[i] = Int(p)
    let base = 2 + n
    var max_distance: Int64 = 0
    for i in range(n):
        for j in range(n):
            let distance = input[base + i * n + j]
            if distance < 0 or distance > 255: return -1
            if (i == j and distance != 0) or (i != j and distance == 0): return -1
            if distance > max_distance: max_distance = distance
    for i in range(n):
        for j in range(n):
            let distance = input[base + i * n + j]
            if distance != input[base + j * n + i]: return -1
            for k in range(n):
                if distance > input[base + i * n + k] + input[base + k * n + j]: return -1
    var high = 0
    while (Int64(1) << high) < max_distance: high += 1
    var clusters = InlineArray[Int, 8](fill=0)
    var next = InlineArray[Int, 8](fill=0)
    var result = InlineArray[Int64, 64](fill=0)
    clusters[0] = (1 << n) - 1
    var count = 1
    var level = high
    while level >= -10:
        let tree_distance = Int64(1) << (level + 13)
        var next_count = 0
        for ci in range(count):
            var remaining = clusters[ci]
            var done = 0
            while remaining != 0:
                var center = n
                for p in range(n):
                    let candidate = permutation[p]
                    if (remaining & (1 << candidate)) != 0:
                        center = candidate
                        break
                if center == n: return -1
                var child = 0
                for v in range(n):
                    if (remaining & (1 << v)) == 0: continue
                    let distance = input[base + center * n + v]
                    var inside = False
                    if level >= 0:
                        inside = distance * 1024 <= beta * (Int64(1) << level)
                    else:
                        inside = distance * 1024 * (Int64(1) << -level) <= beta
                    if inside: child |= 1 << v
                for u in range(n):
                    if (done & (1 << u)) != 0:
                        for v in range(n):
                            if (child & (1 << v)) != 0:
                                result[u * n + v] = tree_distance
                                result[v * n + u] = tree_distance
                done |= child
                remaining &= ~child
                next[next_count] = child
                next_count += 1
        for i in range(next_count): clusters[i] = next[i]
        count = next_count
        level -= 1
    let bytes = 8 * n * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n * n):
        var bits = UInt64(result[i])
        for b in range(8):
            output[8 * i + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
