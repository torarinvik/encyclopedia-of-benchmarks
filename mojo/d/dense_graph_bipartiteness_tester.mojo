# Independent bounded induced-sample tester; see package rights note.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn adjacent(row: Int64, vertex: Int) -> Bool:
    return ((row >> vertex) & 1) != 0

@export("dense_graph_bipartiteness_tester")
fn dense_graph_bipartiteness_tester(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 82: return -1
    let nv = input[0]
    let qv = input[1]
    if nv < 1 or nv > 64 or qv < 1 or qv > 16 or qv > nv: return -1
    let n = Int(nv)
    let q = Int(qv)
    if length != c_size_t(2+n+q): return -1
    for i in range(n):
        let row = input[2+i]
        if n < 64 and (row < 0 or (row >> n) != 0): return -1
        if adjacent(row, i): return -1
        for j in range(i+1, n):
            if adjacent(row, j) != adjacent(input[2+j], i): return -1
    var remaining = List[Int](capacity=n)
    for i in range(n): remaining.append(i)
    var sample = List[Int](capacity=q)
    for i in range(q):
        let draw = input[2+n+i]
        if draw < 0 or draw >= Int64(n-i): return -1
        let selected = i + Int(draw)
        let temp = remaining[i]
        remaining[i] = remaining[selected]
        remaining[selected] = temp
        sample.append(remaining[i])
    var edges = List[Bool](capacity=q*q)
    for _ in range(q*q): edges.append(False)
    for i in range(q):
        for j in range(i+1, q):
            let edge = adjacent(input[2+sample[i]], sample[j])
            edges[i*q+j] = edge
            edges[j*q+i] = edge
    var colors = List[Int](capacity=q)
    var queue = List[Int](capacity=q)
    for _ in range(q): colors.append(-1)
    var accepted = Int64(1)
    for start in range(q):
        if colors[start] != -1: continue
        colors[start] = 0
        queue.clear()
        queue.append(start)
        var head = 0
        while head < len(queue):
            let vertex = queue[head]
            head += 1
            for neighbor in range(q):
                if edges[vertex*q+neighbor]:
                    if colors[neighbor] == -1:
                        colors[neighbor] = 1-colors[vertex]
                        queue.append(neighbor)
                    elif colors[neighbor] == colors[vertex]:
                        accepted = 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    let queries = Int64(q*(q-1) // 2)
    for byte in range(8):
        output[byte] = UInt8((accepted >> (8*byte)) & 255)
        output[8+byte] = UInt8((queries >> (8*byte)) & 255)
    return 16
