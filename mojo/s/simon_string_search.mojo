from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("simon_string_search")
fn simon_string_search(a: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if a == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 274: return -2
    let tl = a[0]
    let ml = a[1]
    if tl < 0 or tl > 256 or ml < 1 or ml > 16 or n != c_size_t(2 + tl + ml): return -2
    for i in range(Int(tl + ml)):
        if a[i + 2] < 0 or a[i + 2] > 15: return -2
    let text_length = Int(tl)
    let m = Int(ml)
    let p = 2 + text_length
    var head = InlineArray[Int, 16](fill=-1)
    var edge_target = InlineArray[Int, 16](fill=0)
    var edge_next = InlineArray[Int, 16](fill=0)
    var edge_count = 0
    var ell = -1
    for i in range(1, m):
        let k = ell
        var cell = -1 if k < 0 else head[k]
        ell = -1
        if a[p + i] == a[p + k + 1]:
            ell = k + 1
        else:
            edge_target[edge_count] = k + 1
            edge_next[edge_count] = head[i - 1]
            head[i - 1] = edge_count
            edge_count += 1
        while cell >= 0:
            let q = edge_target[cell]
            if a[p + i] == a[p + q]:
                ell = q
            else:
                edge_target[edge_count] = q
                edge_next[edge_count] = head[i - 1]
                head[i - 1] = edge_count
                edge_count += 1
            cell = edge_next[cell]
    var state = -1
    var matches = 0
    for j in range(text_length):
        let symbol = a[2 + j]
        if state < m - 1 and a[p + state + 1] == symbol:
            state += 1
        elif state >= 0:
            var edge = head[state]
            state = -1
            while edge >= 0:
                let q = edge_target[edge]
                if a[p + q] == symbol:
                    state = q
                    break
                edge = edge_next[edge]
        if state >= m - 1:
            matches += 1
            state = ell
    return matches
