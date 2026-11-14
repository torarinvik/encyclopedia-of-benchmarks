# MiBench FIFO label-correcting shortest-path profile.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("mibench_network_dijkstra")
fn mibench_network_dijkstra(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let nv = input[0]
    if nv < 1 or nv > 6 or length != c_size_t(2+nv*nv): return -1
    let source = input[1]
    if source < 0 or source >= nv: return -1
    let n = Int(nv)
    var matrix = List[Int64](capacity=n*n)
    for i in range(n*n):
        let cost = input[2+i]
        if cost != 9999 and (cost < 0 or cost > 31): return -1
        matrix.append(cost)
    var distances = List[Int64](capacity=n)
    var reached = List[Bool](capacity=n)
    for _ in range(n):
        distances.append(9999)
        reached.append(False)
    distances[Int(source)] = 0
    reached[Int(source)] = True
    var queue_nodes = List[Int](capacity=1024)
    var queue_distances = List[Int64](capacity=1024)
    queue_nodes.append(Int(source))
    queue_distances.append(0)
    var head = 0
    while head < len(queue_nodes):
        let node = queue_nodes[head]
        let queued_distance = queue_distances[head]
        head += 1
        for destination in range(n):
            let cost = matrix[node*n+destination]
            if cost == 9999: continue
            let candidate = queued_distance + cost
            if not reached[destination] or candidate < distances[destination]:
                reached[destination] = True
                distances[destination] = candidate
                if len(queue_nodes) >= 1024: return -2
                queue_nodes.append(destination)
                queue_distances.append(candidate)
    var checksum = Int64(0)
    var mask = Int64(0)
    for i in range(n):
        if reached[i]:
            checksum += Int64(i+1) * distances[i]
            mask |= Int64(1) << i
    return checksum + mask
