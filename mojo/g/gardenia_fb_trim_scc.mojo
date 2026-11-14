# Independent bounded GARDENIA FB-Trim profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn reach(rows: List[Int], active: Int, pivot: Int, reverse: Bool, n: Int) -> Int:
    var seen = 1 << pivot
    while True:
        var expanded = seen
        for u in range(n):
            if (seen & (1 << u)) == 0: continue
            for v in range(n):
                if (active & (1 << v)) == 0: continue
                var edge = (rows[u] & (1 << v)) != 0
                if reverse: edge = (rows[v] & (1 << u)) != 0
                if edge: expanded |= 1 << v
        if expanded == seen: return seen
        seen = expanded

@export("gardenia_fb_trim_scc")
fn gardenia_fb_trim_scc(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var labels = List[Int64](capacity=n)
    for _ in range(n):
        rows.append(0)
        labels.append(0)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or u >= nv or v < 0 or v >= nv: return -1
        let a = Int(u)
        let bit = 1 << Int(v)
        if (rows[a] & bit) != 0: return -1
        rows[a] |= bit
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var tasks = List[Int](capacity=34)
    tasks.append((1 << n)-1)
    while len(tasks) > 0:
        var active = tasks.pop()
        while active != 0:
            var trimmed = 0
            for u in range(n):
                let bit = 1 << u
                if (active & bit) == 0: continue
                var has_in = False
                let has_out = (rows[u] & active) != 0
                for v in range(n):
                    if (active & (1 << v)) != 0 and (rows[v] & bit) != 0: has_in = True
                if not has_in or not has_out: trimmed |= bit
            if trimmed == 0: break
            for u in range(n):
                if (trimmed & (1 << u)) != 0: labels[u] = Int64(u)
            active &= ~trimmed
        if active == 0: continue
        var pivot = 0
        while (active & (1 << pivot)) == 0: pivot += 1
        let forward = reach(rows,active,pivot,False,n)
        let backward = reach(rows,active,pivot,True,n)
        let component = forward & backward
        var representative = 0
        while (component & (1 << representative)) == 0: representative += 1
        for u in range(n):
            if (component & (1 << u)) != 0: labels[u] = Int64(representative)
        let neither = active & ~(forward | backward)
        let forward_only = forward & ~backward
        let backward_only = backward & ~forward
        if neither != 0: tasks.append(neither)
        if forward_only != 0: tasks.append(forward_only)
        if backward_only != 0: tasks.append(backward_only)
    for u in range(n):
        for byte in range(8): output[8*u+byte] = UInt8((labels[u] >> (8*byte)) & 255)
    return Int64(8*n)
