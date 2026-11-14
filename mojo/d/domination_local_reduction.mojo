# Independent bounded domination reduction; see package rights note.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("domination_local_reduction")
fn domination_local_reduction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 135: return -1
    let nv = input[0]
    let mv = input[1]
    let pv = input[2]
    if nv < 1 or nv > 12 or mv < 0 or mv > 66 or pv < 0 or pv >= nv or length != c_size_t(3+2*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    let pivot = Int(pv)
    var rows = List[Int64](capacity=n)
    for _ in range(n): rows.append(0)
    for edge in range(m):
        let u = input[3+2*edge]
        let v = input[4+2*edge]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (Int64(1) << b)) != 0: return -1
        rows[a] |= Int64(1) << b
        rows[b] |= Int64(1) << a
    let neighbors = rows[pivot]
    let closed = neighbors | (Int64(1) << pivot)
    var exits = Int64(0)
    for u in range(n):
        let bit = Int64(1) << u
        if (neighbors & bit) != 0 and (rows[u] & ~closed) != 0: exits |= bit
    var guards = Int64(0)
    var prisoners = Int64(0)
    for u in range(n):
        let bit = Int64(1) << u
        if (neighbors & bit) != 0 and (exits & bit) == 0:
            if (rows[u] & exits) != 0: guards |= bit
            else: prisoners |= bit
    if prisoners == 0: return -1
    var ids = List[Int](capacity=n)
    var pivot_index = 0
    for u in range(n):
        if ((guards | prisoners) & (Int64(1) << u)) == 0:
            if u == pivot: pivot_index = len(ids)
            ids.append(u)
    let kept = len(ids)
    let k = kept+1
    let bytes = 8*(1+2*k)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var words = List[Int64](capacity=1+2*k)
    words.append(Int64(k))
    for i in range(kept): words.append(Int64(ids[i]))
    words.append(-1)
    for i in range(kept):
        var mask = Int64(0)
        for j in range(kept):
            if (rows[ids[i]] & (Int64(1) << ids[j])) != 0: mask |= Int64(1) << j
        if i == pivot_index: mask |= Int64(1) << kept
        words.append(mask)
    words.append(Int64(1) << pivot_index)
    for i in range(len(words)):
        for byte in range(8): output[8*i+byte] = UInt8((words[i] >> (8*byte)) & 255)
    return Int64(bytes)
