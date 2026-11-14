from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("hub_labeling_greedy_order")
fn hub_labeling_greedy_order(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 58: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 28: return -1
    let n = Int(input[0]); let m = Int(input[1])
    if length != c_size_t(2+2*m): return -1
    var adjacent = InlineArray[Bool, 64](fill=False)
    var prior_u: Int64 = -1; var prior_v: Int64 = -1
    for i in range(m):
        let u = input[2+2*i]; let v = input[3+2*i]
        if u < 0 or v <= u or v >= Int64(n) or u < prior_u or (u == prior_u and v <= prior_v): return -1
        prior_u = u; prior_v = v
        adjacent[Int(u)*8+Int(v)] = True; adjacent[Int(v)*8+Int(u)] = True
    var parent = InlineArray[Int, 64](fill=-1)
    var distance = InlineArray[Int, 64](fill=-1)
    for source in range(n):
        var ways = InlineArray[Int, 8](fill=0)
        var queue = InlineArray[Int, 8](fill=0)
        var head = 0; var tail = 1
        queue[0] = source; distance[source*8+source] = 0; ways[source] = 1
        while head < tail:
            let u = queue[head]; head += 1
            for v in range(n):
                if not adjacent[u*8+v]: continue
                if distance[source*8+v] < 0:
                    distance[source*8+v] = distance[source*8+u]+1
                    parent[source*8+v] = u; ways[v] = ways[u]
                    queue[tail] = v; tail += 1
                elif distance[source*8+v] == distance[source*8+u]+1:
                    ways[v] += ways[u]
                    if ways[v] > 2: ways[v] = 2
        for v in range(n):
            if ways[v] != 1: return -1
    var active = InlineArray[Bool, 64](fill=True)
    var order = InlineArray[Int, 8](fill=0)
    var rank = InlineArray[Int, 8](fill=0)
    for turn in range(n):
        var counts = InlineArray[Int, 8](fill=0)
        for source in range(n):
            for target in range(n):
                if active[source*8+target]:
                    var node = target
                    while True:
                        counts[node] += 1
                        if node == source: break
                        node = parent[source*8+node]
        var best = 0
        for v in range(1, n):
            if counts[v] > counts[best]: best = v
        order[turn] = best; rank[best] = turn
        for source in range(n):
            for target in range(n):
                if not active[source*8+target]: continue
                var node = target
                while True:
                    if node == best:
                        active[source*8+target] = False
                        break
                    if node == source: break
                    node = parent[source*8+node]
    var labels = InlineArray[Int, 64](fill=-1)
    for u in range(n):
        for v in range(u, n):
            var node = v
            var hub = v
            while node != u:
                node = parent[u*8+node]
                if rank[node] < rank[hub]: hub = node
            labels[u*8+hub] = distance[u*8+hub]
            labels[v*8+hub] = distance[v*8+hub]
    var fields = InlineArray[Int64, 81](fill=0)
    fields[0] = Int64(n)
    var used = 1
    for i in range(n):
        fields[used] = Int64(order[i]); used += 1
    for v in range(n):
        let count_index = used; used += 1
        var count = 0
        for hub in range(n):
            let d = labels[v*8+hub]
            if d >= 0:
                fields[used] = Int64(hub | (d << 8)); used += 1; count += 1
        fields[count_index] = Int64(count)
    let bytes = 8*used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(used):
        let bits = UInt64(fields[i])
        for b in range(8): output[8*i+b] = UInt8((bits >> (8*b)) & 255)
    return Int64(bytes)
