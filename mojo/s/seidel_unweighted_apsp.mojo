from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("seidel_unweighted_apsp")
fn seidel_unweighted_apsp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    if input[0] < 1 or input[0] > 8: return -1
    let n = Int(input[0])
    if length != c_size_t(1 + n * n): return -1
    var levels = InlineArray[Int64, 256](fill=0)
    for i in range(n):
        for j in range(n):
            let value = input[1 + i * n + j]
            if value < 0 or value > 1 or (i == j and value != 0): return -1
            levels[8 * i + j] = value
    for i in range(n):
        for j in range(i):
            if levels[8 * i + j] != levels[8 * j + i]: return -1
    var seen = InlineArray[Bool, 8](fill=False)
    var queue = InlineArray[Int, 8](fill=0)
    seen[0] = True
    var head = 0
    var tail = 1
    while head < tail:
        let vertex = queue[head]
        head += 1
        for other in range(n):
            if levels[8 * vertex + other] != 0 and not seen[other]:
                seen[other] = True
                queue[tail] = other
                tail += 1
    if tail != n: return -1
    let bytes = 8 * n * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var level = 0
    var complete = False
    while not complete:
        complete = True
        for i in range(n):
            for j in range(n):
                if i != j and levels[64 * level + 8 * i + j] == 0: complete = False
        if not complete:
            for i in range(n):
                for j in range(n):
                    var paths = Int64(0)
                    for k in range(n):
                        paths += levels[64 * level + 8 * i + k] * levels[64 * level + 8 * k + j]
                    if i != j and (levels[64 * level + 8 * i + j] != 0 or paths > 0):
                        levels[64 * (level + 1) + 8 * i + j] = 1
            level += 1
    var result = InlineArray[Int64, 64](fill=0)
    var next = InlineArray[Int64, 64](fill=0)
    for i in range(n):
        for j in range(n):
            if i != j: result[8 * i + j] = 1
    while level > 0:
        level -= 1
        for i in range(n):
            for j in range(n):
                if i == j:
                    next[8 * i + j] = 0
                else:
                    var degree = Int64(0)
                    var neighbor_sum = Int64(0)
                    for k in range(n):
                        let edge = levels[64 * level + 8 * k + j]
                        degree += edge
                        neighbor_sum += result[8 * i + k] * edge
                    var distance = 2 * result[8 * i + j]
                    if neighbor_sum < result[8 * i + j] * degree: distance -= 1
                    next[8 * i + j] = distance
        for i in range(n):
            for j in range(n): result[8 * i + j] = next[8 * i + j]
    for i in range(n):
        for j in range(n):
            let bits = UInt64(result[8 * i + j])
            for byte in range(8): output[8 * (i * n + j) + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
