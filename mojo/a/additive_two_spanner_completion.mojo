from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn a2_put(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

fn a2_distances(n: Int, m: Int, u: InlineArray[Int, 28], v: InlineArray[Int, 28],
                selected: InlineArray[Bool, 28], only_selected: Bool) -> InlineArray[Int, 64]:
    var distance = InlineArray[Int, 64](fill=9)
    for left in range(n):
        distance[left * 8 + left] = 0
    for edge in range(m):
        if only_selected and not selected[edge]: continue
        distance[u[edge] * 8 + v[edge]] = 1
        distance[v[edge] * 8 + u[edge]] = 1
    for via in range(n):
        for left in range(n):
            for right in range(n):
                let candidate = distance[left * 8 + via] + distance[via * 8 + right]
                if candidate < distance[left * 8 + right]: distance[left * 8 + right] = candidate
    return distance

@export("additive_two_spanner_completion")
fn additive_two_spanner_completion(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 59: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > 8 or m64 < 0 or m64 > 28: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1
    var u = InlineArray[Int, 28](fill=0)
    var v = InlineArray[Int, 28](fill=0)
    for edge in range(m):
        let a64 = input[2 + 2 * edge]
        let b64 = input[3 + 2 * edge]
        if a64 < 0 or a64 >= b64 or b64 >= n64: return -1
        u[edge] = Int(a64)
        v[edge] = Int(b64)
        for prior in range(edge):
            if u[prior] == u[edge] and v[prior] == v[edge]: return -1
    var selected = InlineArray[Bool, 28](fill=False)
    let original = a2_distances(n, m, u, v, selected, False)
    for round in range(m + 1):
        let current = a2_distances(n, m, u, v, selected, True)
        var source = n
        var target = n
        for a in range(n):
            if source != n: break
            for b in range(a + 1, n):
                if original[a * 8 + b] < 9 and current[a * 8 + b] > original[a * 8 + b] + 2:
                    source = a
                    target = b
                    break
        if source == n: break
        if round == m: return -1
        var vertex = source
        while vertex != target:
            var next = n
            for neighbor in range(n):
                if neighbor == vertex or original[neighbor * 8 + target] + 1 != original[vertex * 8 + target]: continue
                for edge in range(m):
                    if (u[edge] == vertex and v[edge] == neighbor) or (v[edge] == vertex and u[edge] == neighbor):
                        next = neighbor
                        selected[edge] = True
                        break
                if next != n: break
            if next == n: return -1
            vertex = next
    var count = 0
    for edge in range(m):
        if selected[edge]: count += 1
    let bytes = 8 * (1 + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    a2_put(output, 0, Int64(count))
    var slot = 0
    for edge in range(m):
        if not selected[edge]: continue
        a2_put(output, 8 * (1 + 2 * slot), Int64(u[edge]))
        a2_put(output, 8 * (2 + 2 * slot), Int64(v[edge]))
        slot += 1
    return Int64(bytes)
