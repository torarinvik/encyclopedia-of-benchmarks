from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn median_cost(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int,
               centers: InlineArray[Int, 4], k: Int) -> Int64:
    var total: Int64 = 0
    for i in range(n):
        var best: Int64 = 1001
        for j in range(k):
            let distance = input[2 + i * n + centers[j]]
            if distance < best: best = distance
        total += best
    return total

@export("k_median_p1_local_search")
fn k_median_p1_local_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 150: return -1
    if input[0] < 2 or input[0] > 12 or input[1] < 1 or input[1] > 4 or input[1] > input[0]: return -1
    let n = Int(input[0])
    let k = Int(input[1])
    if Int(length) != 2 + n * n + k: return -1
    for i in range(n):
        for j in range(n):
            let distance = input[2 + i * n + j]
            if distance < 0 or distance > 1000: return -1
            if (i == j and distance != 0) or (i != j and distance == 0): return -1
            if distance != input[2 + j * n + i]: return -1
    for i in range(n):
        for j in range(n):
            for h in range(n):
                if input[2 + i * n + j] > input[2 + i * n + h] + input[2 + h * n + j]: return -1
    var centers = InlineArray[Int, 4](fill=0)
    var selected = InlineArray[Bool, 12](fill=False)
    for i in range(k):
        let c = input[2 + n * n + i]
        if c < 0 or c >= Int64(n): return -1
        if selected[Int(c)]: return -1
        selected[Int(c)] = True
        centers[i] = Int(c)
    for i in range(1, k):
        let value = centers[i]
        var j = i
        while j > 0 and centers[j - 1] > value:
            centers[j] = centers[j - 1]
            j -= 1
        centers[j] = value
    var current = median_cost(input, n, centers, k)
    while True:
        var best = current
        var best_centers = centers
        var found = False
        for leave in range(k):
            for enter in range(n):
                if selected[enter]: continue
                var candidate = centers
                candidate[leave] = enter
                for i in range(1, k):
                    let value = candidate[i]
                    var j = i
                    while j > 0 and candidate[j - 1] > value:
                        candidate[j] = candidate[j - 1]
                        j -= 1
                    candidate[j] = value
                let value = median_cost(input, n, candidate, k)
                var lex_less = False
                for i in range(k):
                    if candidate[i] != best_centers[i]:
                        lex_less = candidate[i] < best_centers[i]
                        break
                if value < current and (value < best or (value == best and (not found or lex_less))):
                    best = value
                    best_centers = candidate
                    found = True
        if not found: break
        for i in range(k): selected[centers[i]] = False
        centers = best_centers
        for i in range(k): selected[centers[i]] = True
        current = best
    let bytes = 8 * (2 + k)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(2 + k):
        var value = current
        if word == 1: value = Int64(k)
        elif word >= 2: value = Int64(centers[word - 2])
        var bits = UInt64(value)
        for b in range(8):
            output[8 * word + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
