from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("timetable_earliest_arrival_dijkstra")
fn timetable_earliest_arrival_dijkstra(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 138: return -1
    let nv = input[0]; let av = input[1]; let sv = input[2]; let tv = input[3]; let start = input[4]
    if nv < 2 or nv > 8 or av < 0 or av > 12 or sv < 0 or sv >= nv or tv < 0 or tv >= nv or start < 0 or start > 1000: return -1
    let n = Int(nv); let arcs = Int(av); let source = Int(sv); let target = Int(tv)
    var froms = List[Int](capacity=arcs)
    var tos = List[Int](capacity=arcs)
    var counts = List[Int](capacity=arcs)
    var departures = List[Int64](capacity=4*arcs)
    var arrivals = List[Int64](capacity=4*arcs)
    var seen = List[Int](capacity=n)
    for _ in range(n): seen.append(0)
    var cursor = 5
    for _ in range(arcs):
        if c_size_t(cursor+3) > length: return -1
        let u = input[cursor]; let v = input[cursor+1]; let count = input[cursor+2]
        cursor += 3
        if u < 0 or u >= nv or v < 0 or v >= nv or u == v or count < 1 or count > 4: return -1
        if c_size_t(cursor+2*Int(count)) > length: return -1
        let a = Int(u); let b = Int(v)
        if (seen[a] & (1 << b)) != 0: return -1
        seen[a] |= 1 << b
        froms.append(a); tos.append(b); counts.append(Int(count))
        var previous_departure = Int64(-1)
        var previous_arrival = Int64(-1)
        for j in range(4):
            if j < Int(count):
                let dep = input[cursor]; let arr = input[cursor+1]
                cursor += 2
                if dep < 0 or dep > 1000 or arr <= dep or arr > 2000 or dep <= previous_departure or arr < previous_arrival: return -1
                departures.append(dep); arrivals.append(arr)
                previous_departure = dep; previous_arrival = arr
            else:
                departures.append(0); arrivals.append(0)
    if c_size_t(cursor) != length: return -1
    let infinity = Int64(1000000)
    var distance = List[Int64](capacity=n)
    var parent = List[Int](capacity=n)
    var settled = List[Bool](capacity=n)
    for _ in range(n): distance.append(infinity); parent.append(-1); settled.append(False)
    distance[source] = start
    for _ in range(n):
        var u = -1
        for vertex in range(n):
            if not settled[vertex] and distance[vertex] < infinity:
                if u < 0: u = vertex
                elif distance[vertex] < distance[u]: u = vertex
        if u < 0: break
        settled[u] = True
        for edge in range(arcs):
            let v = tos[edge]
            if froms[edge] != u or settled[v]: continue
            var trip = 0
            while trip < counts[edge] and departures[4*edge+trip] < distance[u]: trip += 1
            if trip == counts[edge]: continue
            let candidate = arrivals[4*edge+trip]
            if candidate < distance[v] or (candidate == distance[v] and (parent[v] < 0 or u < parent[v])):
                distance[v] = candidate
                parent[v] = u
    var path = List[Int](capacity=n)
    if distance[target] < infinity:
        var current = target
        path.append(current)
        while current != source and len(path) < n:
            if parent[current] < 0: return -1
            current = parent[current]
            path.append(current)
        if current != source: return -1
    let bytes = 8*(3+len(path))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(3+len(path)):
        var value = Int64(0)
        if i == 0:
            if len(path) > 0: value = 1
        elif i == 1:
            value = -1
            if len(path) > 0: value = distance[target]
        elif i == 2: value = Int64(len(path))
        else: value = Int64(path[len(path)-1-(i-3)])
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
