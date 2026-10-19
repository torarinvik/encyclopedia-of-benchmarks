from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 64

@export("bellman_ford")
fn bellman_ford(edges: UnsafePointer[Int64, ImmutAnyOrigin], vertices: c_size_t, edge_count: c_size_t,
        source: c_size_t, distances: UnsafePointer[Int64, MutAnyOrigin],
        reachable: UnsafePointer[UInt8, MutAnyOrigin]) abi("C") -> Int64:
    if vertices == 0:
        return 0 if source == 0 and edge_count == 0 else -3
    if vertices > MAX_VERTICES or source >= vertices: return -3
    if edge_count > 0 and edges == UnsafePointer[Int64, ImmutAnyOrigin](): return -3
    if distances == UnsafePointer[Int64, MutAnyOrigin]() or reachable == UnsafePointer[UInt8, MutAnyOrigin](): return -3
    for edge in range(edge_count):
        let origin = edges[3 * edge]
        let destination = edges[3 * edge + 1]
        if origin < 0 or destination < 0 or origin >= vertices or destination >= vertices: return -3
    for vertex in range(vertices):
        distances[vertex] = 0
        reachable[vertex] = 0
    reachable[source] = 1
    for round in range(vertices):
        var changed = False
        for edge in range(edge_count):
            let origin = Int(edges[3 * edge])
            let destination = Int(edges[3 * edge + 1])
            let weight = edges[3 * edge + 2]
            if reachable[origin] == 0: continue
            let base = distances[origin]
            if (weight > 0 and base > 9223372036854775807 - weight) or
               (weight < 0 and base < (-9223372036854775807 - 1) - weight): return -2
            let candidate = base + weight
            if reachable[destination] == 0 or candidate < distances[destination]:
                if round == Int(vertices) - 1: return -1
                distances[destination] = candidate
                reachable[destination] = 1
                changed = True
        if not changed: return 0
    return 0
