from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(mut b: List[UInt8], v: Int64):
    var bits = v
    for _ in range(8): b.append(UInt8(bits & 255)); bits >>= 8

@export("bidirectional_breadth_first_search")
fn bidirectional_breadth_first_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 69: return -1
    let rv = input[0]; let cv = input[1]; let sv = input[2]; let gv = input[3]; let bv = input[4]
    if rv < 1 or rv > 8 or cv < 1 or cv > 8: return -1
    let rows = Int(rv); let cols = Int(cv); let cells = rows * cols
    if sv < 0 or sv >= cells or gv < 0 or gv >= cells or bv < 0 or bv > cells or length != c_size_t(5 + bv): return -1
    let start = Int(sv); let goal = Int(gv)
    var blocked = List[Bool](capacity=cells)
    for _ in range(cells): blocked.append(False)
    for i in range(Int(bv)):
        let v = input[5 + i]
        if v < 0 or v >= cells or blocked[Int(v)]: return -1
        blocked[Int(v)] = True
    if blocked[start] or blocked[goal]: return -1
    var dist0 = List[Int](capacity=cells); var dist1 = List[Int](capacity=cells)
    var p0 = List[Int](capacity=cells); var p1 = List[Int](capacity=cells)
    for _ in range(cells): dist0.append(-1); dist1.append(-1); p0.append(-1); p1.append(-1)
    var q0 = List[Int](capacity=cells); var q1 = List[Int](capacity=cells)
    dist0[start] = 0; dist1[goal] = 0; q0.append(start); q1.append(goal)
    var h0 = 0; var h1 = 0; var meet = -1
    if start == goal: meet = start
    while meet < 0 and h0 < len(q0) and h1 < len(q1):
        for side in range(2):
            if meet >= 0: break
            let end = len(q0) if side == 0 else len(q1)
            while (h0 if side == 0 else h1) < end:
                let u = q0[h0] if side == 0 else q1[h1]
                if side == 0: h0 += 1
                else: h1 += 1
                let row = u // cols; let col = u % cols
                var neighbors = List[Int](capacity=4)
                if row > 0: neighbors.append(u - cols)
                if col > 0: neighbors.append(u - 1)
                if row + 1 < rows: neighbors.append(u + cols)
                if col + 1 < cols: neighbors.append(u + 1)
                for v in neighbors:
                    if blocked[v]: continue
                    if side == 0:
                        if dist0[v] >= 0: continue
                        dist0[v] = dist0[u] + 1; p0[v] = u; q0.append(v)
                        if dist1[v] >= 0: meet = v; break
                    else:
                        if dist1[v] >= 0: continue
                        dist1[v] = dist1[u] + 1; p1[v] = u; q1.append(v)
                        if dist0[v] >= 0: meet = v; break
                if meet >= 0: break
    var path = List[Int](capacity=cells)
    if meet >= 0:
        var rev = List[Int](capacity=cells); var v = meet
        while v >= 0: rev.append(v); v = p0[v]
        for j in range(len(rev) - 1, -1, -1): path.append(rev[j])
        v = p1[meet]
        while v >= 0: path.append(v); v = p1[v]
    var bytes = List[UInt8](capacity=(1 + len(path)) * 8)
    put_word(bytes, Int64(len(path))); for v in path: put_word(bytes, Int64(v))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
