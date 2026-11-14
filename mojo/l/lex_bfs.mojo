# Independent bounded LexBFS profile; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("lex_bfs")
fn lex_bfs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 243: return -1
    let nv = input[0]
    let mv = input[1]
    let sv = input[2]
    if nv < 1 or nv > 16 or mv < 0 or mv > 120 or sv < 0 or sv >= nv or length != c_size_t(3+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var labels = List[Int](capacity=n*n)
    var lengths = List[Int](capacity=n)
    var order = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        lengths.append(0)
    for _ in range(n*n): labels.append(0)
    for e in range(Int(mv)):
        let u = input[3+2*e]
        let v = input[4+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var selected = 0
    var current = Int(sv)
    for step in range(n):
        if step > 0:
            current = -1
            for u in range(n):
                if (selected & (1 << u)) != 0: continue
                if current == -1:
                    current = u
                    continue
                var p = 0
                var decided = False
                while p < lengths[u] and p < lengths[current]:
                    if labels[u*n+p] != labels[current*n+p]:
                        if labels[u*n+p] > labels[current*n+p]: current = u
                        decided = True
                        break
                    p += 1
                if not decided and lengths[u] > lengths[current]: current = u
        selected |= 1 << current
        order.append(current)
        for v in range(n):
            if (rows[current] & (1 << v)) == 0 or (selected & (1 << v)) != 0: continue
            labels[v*n+lengths[v]] = n - step
            lengths[v] += 1
    for i in range(n):
        let value = Int64(order[i])
        for byte in range(8): output[8*i+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(8*n)
