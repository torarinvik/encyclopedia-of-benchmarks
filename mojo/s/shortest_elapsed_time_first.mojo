from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("shortest_elapsed_time_first")
fn shortest_elapsed_time_first(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 18: return -1
    let n0 = input[0]
    if n0 < 0 or n0 > 8 or length != c_size_t(1 + 2 * n0): return -1
    let n = Int(n0)
    var release = List[Int64](length=n, fill=0)
    var remaining = List[Int64](length=n, fill=0)
    var attained = List[Int64](length=n, fill=0)
    for job in range(n):
        release[job] = input[1 + 2 * job]
        remaining[job] = input[2 + 2 * job]
        if release[job] < 0 or release[job] > 16 or remaining[job] < 1 or remaining[job] > 12: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var trace = List[UInt8]()
    var completed = 0
    while completed < n and len(trace) < 112:
        var chosen = n
        for job in range(n):
            if release[job] <= Int64(len(trace)) and remaining[job] > 0:
                if chosen == n or attained[job] < attained[chosen]: chosen = job
        var action = UInt8(0)
        if chosen < n:
            action = UInt8(chosen + 1)
            attained[chosen] += 1
            remaining[chosen] -= 1
            if remaining[chosen] == 0: completed += 1
        trace.append(action)
    if completed != n: return -1
    if capacity < c_size_t(len(trace)): return -2
    for i in range(len(trace)): output[i] = trace[i]
    return Int64(len(trace))
