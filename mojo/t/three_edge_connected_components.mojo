from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn refine(u: InlineArray[Int, 32], v: InlineArray[Int, 32], n: Int, m: Int,
          removed_a: Int, removed_b: Int, mut same: InlineArray[Bool, 64]):
    var component = InlineArray[Int, 8](fill=-1)
    var queue = InlineArray[Int, 8](fill=0)
    var next_component = 0
    for start in range(n):
        if component[start] >= 0: continue
        component[start] = next_component
        queue[0] = start
        var head = 0
        var tail = 1
        while head < tail:
            let vertex = queue[head]
            head += 1
            for edge in range(m):
                if edge == removed_a or edge == removed_b: continue
                var neighbor = -1
                if u[edge] == vertex:
                    neighbor = v[edge]
                elif v[edge] == vertex:
                    neighbor = u[edge]
                if neighbor >= 0 and component[neighbor] < 0:
                    component[neighbor] = next_component
                    queue[tail] = neighbor
                    tail += 1
        next_component += 1
    for first in range(n):
        for second in range(first + 1, n):
            if component[first] != component[second]:
                same[8 * first + second] = False
                same[8 * second + first] = False

@export("three_edge_connected_components")
fn three_edge_connected_components(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let n64 = values[0]
    let m64 = values[1]
    if n64 < 1 or n64 > 8 or m64 < 0 or m64 > 32: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1
    var u = InlineArray[Int, 32](fill=0)
    var v = InlineArray[Int, 32](fill=0)
    for edge in range(m):
        let a = values[2 + 2 * edge]
        let b = values[3 + 2 * edge]
        if a < 0 or a >= n64 or b < 0 or b >= n64: return -1
        u[edge] = Int(a)
        v[edge] = Int(b)
    var same = InlineArray[Bool, 64](fill=True)
    refine(u, v, n, m, -1, -1, mut same)
    for first in range(m):
        refine(u, v, n, m, first, -1, mut same)
        for second in range(first + 1, m): refine(u, v, n, m, first, second, mut same)
    var labels = InlineArray[Int, 8](fill=-1)
    var next_label = 0
    for first in range(n):
        if labels[first] >= 0: continue
        for vertex in range(first, n):
            if labels[vertex] < 0 and same[8 * first + vertex]: labels[vertex] = next_label
        next_label += 1
    var encoded: Int64 = 0
    var place: Int64 = 1
    for vertex in range(n):
        encoded += Int64(labels[vertex]) * place
        place *= 8
    return encoded
