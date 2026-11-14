from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("hub_labeling_pruned")
fn hub_labeling_pruned(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 66: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 28: return -1
    let n = Int(input[0]); let m = Int(input[1])
    if length != c_size_t(2+n+2*m): return -1
    var seen = InlineArray[Bool, 8](fill=False)
    for i in range(n):
        let raw = input[2+i]
        if raw < 0 or raw >= Int64(n): return -1
        let vertex = Int(raw)
        if seen[vertex]: return -1
        seen[vertex] = True
    var adjacent = InlineArray[Bool, 64](fill=False)
    var previous_u: Int64 = -1
    var previous_v: Int64 = -1
    for i in range(m):
        let u = input[2+n+2*i]; let v = input[3+n+2*i]
        if u < 0 or v <= u or v >= Int64(n) or u < previous_u or (u == previous_u and v <= previous_v): return -1
        previous_u = u; previous_v = v
        adjacent[Int(u)*8+Int(v)] = True; adjacent[Int(v)*8+Int(u)] = True
    # Count shortest paths, saturating at two to validate uniqueness.
    for source in range(n):
        var distance = InlineArray[Int, 8](fill=-1)
        var ways = InlineArray[Int, 8](fill=0)
        var queue = InlineArray[Int, 8](fill=0)
        var head = 0; var tail = 1
        distance[source] = 0; ways[source] = 1; queue[0] = source
        while head < tail:
            let vertex = queue[head]; head += 1
            for neighbor in range(n):
                if not adjacent[vertex*8+neighbor]: continue
                if distance[neighbor] < 0:
                    distance[neighbor] = distance[vertex]+1
                    ways[neighbor] = ways[vertex]
                    queue[tail] = neighbor; tail += 1
                elif distance[neighbor] == distance[vertex]+1:
                    ways[neighbor] += ways[vertex]
                    if ways[neighbor] > 2: ways[neighbor] = 2
        for vertex in range(n):
            if ways[vertex] != 1: return -1
    var labels = InlineArray[Int, 64](fill=-1)
    for rank in range(n):
        let hub = Int(input[2+rank])
        var distance = InlineArray[Int, 8](fill=-1)
        var queue = InlineArray[Int, 8](fill=0)
        var head = 0; var tail = 1
        distance[hub] = 0; queue[0] = hub
        while head < tail:
            let vertex = queue[head]; head += 1
            var estimate = 16
            for common in range(n):
                let a = labels[hub*8+common]; let b = labels[vertex*8+common]
                if a >= 0 and b >= 0 and a+b < estimate: estimate = a+b
            if estimate <= distance[vertex]: continue
            labels[vertex*8+hub] = distance[vertex]
            for neighbor in range(n):
                if adjacent[vertex*8+neighbor] and distance[neighbor] < 0:
                    distance[neighbor] = distance[vertex]+1
                    queue[tail] = neighbor; tail += 1
    var fields = InlineArray[Int64, 73](fill=0)
    fields[0] = Int64(n)
    var used = 1
    for vertex in range(n):
        let count_index = used
        used += 1
        var count = 0
        for hub in range(n):
            let d = labels[vertex*8+hub]
            if d >= 0:
                fields[used] = Int64(hub | (d << 8))
                used += 1; count += 1
        fields[count_index] = Int64(count)
    let bytes = 8*used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(used):
        let bits = UInt64(fields[i])
        for b in range(8): output[8*i+b] = UInt8((bits >> (8*b)) & 255)
    return Int64(bytes)
