from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

fn biconnected(n: Int, m: Int, u: InlineArray[Int, 28], v: InlineArray[Int, 28],
               active: InlineArray[Bool, 28]) -> Bool:
    for removed in range(n):
        let start = removed == 0 ? 1 : 0
        var seen = InlineArray[Bool, 8](fill=False)
        var queue = InlineArray[Int, 8](fill=0)
        var head = 0
        var tail = 1
        seen[start] = True
        queue[0] = start
        while head < tail:
            let current = queue[head]
            head += 1
            for edge in range(m):
                if not active[edge] or u[edge] == removed or v[edge] == removed: continue
                var next = n
                if u[edge] == current: next = v[edge]
                elif v[edge] == current: next = u[edge]
                if next < n and not seen[next]:
                    seen[next] = True
                    queue[tail] = next
                    tail += 1
        for vertex in range(n):
            if vertex != removed and not seen[vertex]: return False
    return True

@export("cheriyan_thurimella_two_vertex_connected_augmentation")
fn cheriyan_thurimella_two_vertex_connected_augmentation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 59: return -1
    let input_view = input[0:length]
    let n64 = input_view[0]
    let m64 = input_view[1]
    if n64 < 3 or n64 > 8 or m64 < 3 or m64 > 28: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1

    var u = InlineArray[Int, 28](fill=0)
    var v = InlineArray[Int, 28](fill=0)
    for edge in range(m):
        let a64 = input_view[2 + 2 * edge]
        let b64 = input_view[3 + 2 * edge]
        if a64 < 0 or a64 >= b64 or b64 >= n64: return -1
        let a = Int(a64)
        let b = Int(b64)
        for prior in range(edge):
            if u[prior] == a and v[prior] == b: return -1
        u[edge] = a
        v[edge] = b

    var active = InlineArray[Bool, 28](fill=False)
    for edge in range(m): active[edge] = True
    if not biconnected(n, m, u, v, active): return -1

    let states = 1 << n
    var best = InlineArray[Int, 256](fill=0)
    var choice = InlineArray[Int, 256](fill=-1)
    for mask in range(1, states):
        var first = 0
        while (mask & (1 << first)) == 0: first += 1
        for edge in range(m):
            var other = n
            if u[edge] == first: other = v[edge]
            elif v[edge] == first: other = u[edge]
            if other == n or (mask & (1 << other)) == 0: continue
            let rest = mask & (~(1 << first)) & (~(1 << other))
            let candidate = 1 + best[rest]
            if candidate > best[mask]:
                best[mask] = candidate
                choice[mask] = edge
        let rest = mask & (~(1 << first))
        if best[rest] > best[mask]:
            best[mask] = best[rest]
            choice[mask] = -1

    var cover = InlineArray[Bool, 28](fill=False)
    var covered = InlineArray[Bool, 8](fill=False)
    var mask = states - 1
    while mask != 0:
        var first = 0
        while (mask & (1 << first)) == 0: first += 1
        let edge = choice[mask]
        if edge < 0:
            mask = mask & (~(1 << first))
            continue
        cover[edge] = True
        covered[u[edge]] = True
        covered[v[edge]] = True
        mask = mask & (~(1 << u[edge])) & (~(1 << v[edge]))
    for vertex in range(n):
        if covered[vertex]: continue
        for edge in range(m):
            if u[edge] == vertex or v[edge] == vertex:
                cover[edge] = True
                covered[u[edge]] = True
                covered[v[edge]] = True
                break
    for edge in range(m):
        if cover[edge]: continue
        active[edge] = False
        if not biconnected(n, m, u, v, active): active[edge] = True

    var count = 0
    for edge in range(m):
        if active[edge]: count += 1
    let bytes = 8 * (1 + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    store_i64(output, 0, Int64(count))
    var slot = 0
    for edge in range(m):
        if not active[edge]: continue
        store_i64(output, 8 * (1 + 2 * slot), Int64(u[edge]))
        store_i64(output, 8 * (2 + 2 * slot), Int64(v[edge]))
        slot += 1
    return Int64(bytes)
