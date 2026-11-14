from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("minimal_dominating_sets_interval")
fn minimal_dominating_sets_interval(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 25: return -1
    let count = input[0]
    if count < 1 or count > 12 or length != c_size_t(1 + 2 * count): return -1
    let n = Int(count)
    var start = InlineArray[Int64, 12](fill=0)
    var end = InlineArray[Int64, 12](fill=0)
    var min_end: Int64 = 101
    var max_start: Int64 = -101
    for i in range(n):
        let s = input[1 + 2 * i]
        let e = input[2 + 2 * i]
        if s < -100 or s > 100 or e < -100 or e > 100 or s >= e: return -1
        if i > 0 and start[i - 1] >= s: return -1
        for j in range(i):
            if s == start[j] or s == end[j] or e == start[j] or e == end[j]: return -1
        start[i] = s
        end[i] = e
        min_end = min(min_end, e)
        max_start = max(max_start, s)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var has_next = InlineArray[Bool, 12](fill=False)
    var next_start = InlineArray[Int64, 12](fill=101)
    var next_end = InlineArray[Int64, 12](fill=101)
    var private_end = InlineArray[Int64, 12](fill=101)
    for i in range(n):
        for z in range(n):
            if start[i] <= end[z] and start[z] <= end[i]: private_end[i] = min(private_end[i], end[z])
            if start[z] > end[i]:
                has_next[i] = True
                next_start[i] = min(next_start[i], start[z])
                next_end[i] = min(next_end[i], end[z])
    var valid = InlineArray[Bool, 144](fill=False)
    var pair_end = InlineArray[Int64, 144](fill=101)
    var ways = InlineArray[Int64, 144](fill=0)
    for i in range(n):
        for j in range(i + 1, n):
            let index = 12 * i + j
            for z in range(n):
                let meets_j = start[j] <= end[z] and start[z] <= end[j]
                let meets_i = start[i] <= end[z] and start[z] <= end[i]
                if meets_j and not meets_i: pair_end[index] = min(pair_end[index], end[z])
            valid[index] = has_next[i] and private_end[i] < start[j] and start[j] <= next_end[i] and end[j] >= next_start[i]
    for j in range(1, n):
        for i in range(j):
            let index = 12 * i + j
            if valid[index]:
                if start[i] <= min_end: ways[index] += 1
                for k in range(j + 1, n):
                    let successor = 12 * j + k
                    if valid[successor] and pair_end[index] < start[k] and start[k] <= next_end[j]: ways[successor] += ways[index]
    var answer: Int64 = 0
    for i in range(n):
        if start[i] <= min_end and end[i] >= max_start: answer += 1
        for j in range(i + 1, n):
            if end[j] >= max_start: answer += ways[12 * i + j]
    var bits = UInt64(answer)
    for byte in range(8):
        output[byte] = UInt8(bits & 255)
        bits >>= 8
    return 8
