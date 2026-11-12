from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_V = 16
comptime MAX_E = 32
comptime MAX_INPUT = 66
comptime MAX_OUTPUT = 17

@export("games_on_arbitrary_graphs")
fn games_on_arbitrary_graphs(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT):
        return -1
    let nv = input[0]
    let me = input[1]
    if nv < 0 or nv > MAX_V or me < 0 or me > MAX_E: return -1
    let n = Int(nv)
    let m = Int(me)
    if length != c_size_t(2 + 2 * m): return -1

    var outmask = InlineArray[UInt16, MAX_V](fill=0)
    var head = InlineArray[Int, MAX_V](fill=-1)
    var edge_source = InlineArray[Int, MAX_E](fill=0)
    var edge_next = InlineArray[Int, MAX_E](fill=-1)
    var remaining = InlineArray[Int, MAX_V](fill=0)
    var status = InlineArray[Int, MAX_V](fill=0)
    var queue = InlineArray[Int, MAX_V](fill=0)
    var staged = InlineArray[UInt8, MAX_OUTPUT](fill=0)
    var unique_edges = 0

    for edge_index in range(m):
        let sv = input[2 + 2 * edge_index]
        let tv = input[3 + 2 * edge_index]
        if sv < 0 or sv >= nv or tv < 0 or tv >= nv: return -1
        let s = Int(sv)
        let t = Int(tv)
        let bit = UInt16(1) << t
        if outmask[s] & bit == 0:
            outmask[s] = outmask[s] | bit
            edge_source[unique_edges] = s
            edge_next[unique_edges] = head[t]
            head[t] = unique_edges
            unique_edges += 1
            remaining[s] += 1

    var first = 0
    var count = 0
    for vertex in range(n):
        if remaining[vertex] == 0:
            status[vertex] = 2
            queue[count] = vertex
            count += 1
    while first < count:
        let resolved = queue[first]
        first += 1
        var edge = head[resolved]
        while edge != -1:
            let predecessor = edge_source[edge]
            if status[predecessor] == 0:
                if status[resolved] == 2:
                    status[predecessor] = 1
                    queue[count] = predecessor
                    count += 1
                else:
                    remaining[predecessor] -= 1
                    if remaining[predecessor] == 0:
                        status[predecessor] = 2
                        queue[count] = predecessor
                        count += 1
            edge = edge_next[edge]

    staged[0] = UInt8(n)
    for vertex in range(n): staged[vertex + 1] = UInt8(status[vertex])
    let needed = n + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    for index in range(needed): output[index] = staged[index]
    return Int64(needed)
