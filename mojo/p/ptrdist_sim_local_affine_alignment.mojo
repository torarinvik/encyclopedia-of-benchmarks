# Independent bounded SIM first-best alignment; provenance in package README.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("ptrdist_sim_local_affine_alignment")
fn ptrdist_sim_local_affine_alignment(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 130: return -1
    let lv = input[0]
    if lv < 1 or lv > 64: return -1
    let left = Int(lv); let right_pos = 1+left
    if c_size_t(right_pos) >= length: return -1
    let rv = input[right_pos]
    if rv < 1 or rv > 64: return -1
    let right = Int(rv)
    if length != c_size_t(right_pos+1+right): return -1
    var first = List[Int64](capacity=left)
    var second = List[Int64](capacity=right)
    for i in range(left):
        let c = input[1+i]
        if c != 65 and c != 67 and c != 71 and c != 84: return -1
        first.append(c)
    for i in range(right):
        let c = input[right_pos+1+i]
        if c != 65 and c != 67 and c != 71 and c != 84: return -1
        second.append(c)
    let stride = right+1
    let cells = (left+1)*stride
    var h = List[Int64](length=cells, fill=0)
    var d = List[Int64](length=cells, fill=0)
    var f = List[Int64](length=cells, fill=0)
    for j in range(1,right+1): d[j] = -60
    for i in range(1,left+1): f[i*stride] = -60
    var best = Int64(0)
    for i in range(1,left+1):
        for j in range(1,right+1):
            let p = i*stride+j
            d[p] = h[p-stride]-62
            if d[p-stride]-2 > d[p]: d[p] = d[p-stride]-2
            f[p] = h[p-1]-62
            if f[p-1]-2 > f[p]: f[p] = f[p-1]-2
            var score = h[p-stride-1]-10
            if first[i-1] == second[j-1]: score = h[p-stride-1]+10
            if score < 0: score = 0
            if d[p] > score: score = d[p]
            if f[p] > score: score = f[p]
            h[p] = score
            if score > best: best = score
    return best
