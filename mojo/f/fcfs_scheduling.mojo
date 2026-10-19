from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("fcfs_scheduling")
fn fcfs_scheduling(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 193 or values[0] < 0 or values[0] > 64: return -2
    let n = values[0]
    if length != 1 + 3 * n: return -2
    var ids = InlineArray[Int64, 64](0)
    var arrivals = InlineArray[Int64, 64](0)
    var bursts = InlineArray[Int64, 64](0)
    var order = InlineArray[Int64, 64](0)
    for i in range(n):
        ids[i] = values[1 + 3 * i]
        arrivals[i] = values[2 + 3 * i]
        bursts[i] = values[3 + 3 * i]
        if ids[i] < 0 or ids[i] > 63 or arrivals[i] < 0 or arrivals[i] > 1000000 or bursts[i] < 1 or bursts[i] > 1000000: return -2
        for j in range(i):
            if ids[j] == ids[i]: return -2
        order[i] = i
    for i in range(1, n):
        let key = order[i]
        var j = i
        while j > 0 and (arrivals[order[j - 1]] > arrivals[key] or (arrivals[order[j - 1]] == arrivals[key] and ids[order[j - 1]] > ids[key])):
            order[j] = order[j - 1]
            j -= 1
        order[j] = key
    let bytes = n * 48
    if capacity < bytes or (bytes != 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var stage = InlineArray[Int64, 384](0)
    var elapsed: Int64 = 0
    for p in range(n):
        let i = order[p]
        if elapsed < arrivals[i]: elapsed = arrivals[i]
        let completion = elapsed + bursts[i]
        let turnaround = completion - arrivals[i]
        let base = p * 6
        stage[base] = ids[i]
        stage[base + 1] = arrivals[i]
        stage[base + 2] = bursts[i]
        stage[base + 3] = completion
        stage[base + 4] = turnaround
        stage[base + 5] = turnaround - bursts[i]
        elapsed = completion
    for i in range(n * 6):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return n
