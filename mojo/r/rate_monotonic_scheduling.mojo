from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("rate_monotonic_scheduling")
fn rate_monotonic_scheduling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 17: return -1
    let nv = input[0]
    if nv < 1 or nv > 8 or length != c_size_t(1+2*Int(nv)): return -1
    let n = Int(nv)
    var execution = List[Int](capacity=n)
    var period = List[Int](capacity=n)
    var order = List[Int](capacity=n)
    var response = List[Int64](length=n, fill=-1)
    for i in range(n):
        let c = input[1+2*i]; let t = input[2+2*i]
        if c < 1 or c > 16 or t < 1 or t > 32: return -1
        execution.append(Int(c)); period.append(Int(t)); order.append(i)
    for i in range(1,n):
        let task = order[i]
        var j = i
        while j > 0 and period[order[j-1]] > period[task]:
            order[j] = order[j-1]
            j -= 1
        order[j] = task
    var schedulable = Int64(1)
    var failed = Int64(-1)
    for rank in range(n):
        let target = order[rank]
        var remaining = execution[target]
        var active = List[Int](length=n, fill=0)
        var elapsed = 0
        while remaining > 0 and elapsed < period[target]:
            for h in range(rank):
                let higher = order[h]
                if elapsed%period[higher] == 0: active[higher] += execution[higher]
            var selected = -1
            for h in range(rank):
                let higher = order[h]
                if active[higher] > 0:
                    selected = higher
                    break
            if selected >= 0: active[selected] -= 1
            else: remaining -= 1
            elapsed += 1
        if remaining > 0:
            schedulable = 0; failed = Int64(target)
            break
        response[target] = Int64(elapsed)
    let bytes = 8*(n+2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n+2):
        var value = schedulable
        if i == 1: value = failed
        elif i >= 2: value = response[i-2]
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
