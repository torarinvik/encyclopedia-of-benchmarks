from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("sublinear_bipartiteness_walk_tester")
fn sublinear_bipartiteness_walk_tester(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 330: return -1
    let nv = input[0]; let dv = input[1]; let mv = input[2]
    if nv < 1 or nv > 16 or dv < 3 or dv > 4 or mv < 0 or mv > 32: return -1
    let n = Int(nv); let d = Int(dv); let m = Int(mv)
    if m > n*d//2: return -1
    let suffix = 3+2*m
    if length < c_size_t(suffix+4): return -1
    let tv = input[suffix]; let rv = input[suffix+1]; let lv = input[suffix+2]
    if tv < 1 or tv > 4 or rv < 1 or rv > 8 or lv < 1 or lv > 8: return -1
    let starts_count = Int(tv); let walks = Int(rv); let steps = Int(lv)
    if length != c_size_t(suffix+3+starts_count+starts_count*walks*steps): return -1
    var adjacency = List[Int](capacity=n)
    var degrees = List[Int](capacity=n)
    var neighbors = List[Int](capacity=4*n)
    for _ in range(n): adjacency.append(0); degrees.append(0)
    for _ in range(4*n): neighbors.append(0)
    for i in range(m):
        let av = input[3+2*i]; let bv = input[4+2*i]
        if av < 0 or bv <= av or bv >= nv: return -1
        let a = Int(av); let b = Int(bv)
        if (adjacency[a] & (1 << b)) != 0 or degrees[a] >= d or degrees[b] >= d: return -1
        adjacency[a] |= 1 << b
        adjacency[b] |= 1 << a
        var at = degrees[a]
        degrees[a] += 1
        while at > 0 and neighbors[4*a+at-1] > b:
            neighbors[4*a+at] = neighbors[4*a+at-1]
            at -= 1
        neighbors[4*a+at] = b
        at = degrees[b]
        degrees[b] += 1
        while at > 0 and neighbors[4*b+at-1] > a:
            neighbors[4*b+at] = neighbors[4*b+at-1]
            at -= 1
        neighbors[4*b+at] = a
    let starts_at = suffix+3
    let draws_at = starts_at+starts_count
    for i in range(starts_count):
        if input[starts_at+i] < 0 or input[starts_at+i] >= nv: return -1
    for i in range(starts_count*walks*steps):
        if input[draws_at+i] < 0 or input[draws_at+i] >= 2*dv: return -1
    var accepted = True
    var draw = 0
    for t in range(starts_count):
        if not accepted: break
        let start = Int(input[starts_at+t])
        var seen = List[Int](capacity=n)
        for _ in range(n): seen.append(0)
        seen[start] = 1
        for _ in range(walks):
            if not accepted: break
            var vertex = start
            var parity = 0
            for _ in range(steps):
                let choice = Int(input[draws_at+draw])
                draw += 1
                if choice < degrees[vertex]:
                    vertex = neighbors[4*vertex+choice]
                    parity ^= 1
                seen[vertex] |= 1 << parity
                if seen[vertex] == 3:
                    accepted = False
                    break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    output[0] = 0
    if accepted: output[0] = 1
    for i in range(1,8): output[i] = 0
    return 8
