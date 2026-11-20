# Uncompiled multiword bit-vector global edit-distance draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("myers_bitvector_edit_distance")
fn myers_bitvector_edit_distance(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 515: return -1
    let nr = input[0]
    let mr = input[1]
    if nr < 0 or nr > 256 or mr < 0 or mr > 256 or length != c_size_t(2+nr+mr): return -1
    let n = Int(nr)
    let m = Int(mr)
    for i in range(2,Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    if n == 0: return mr
    var masks = InlineArray[UInt64,1024](fill=0)
    var pv = InlineArray[UInt64,4](fill=~UInt64(0))
    var mv = InlineArray[UInt64,4](fill=0)
    let words = (n+63)//64
    for i in range(n):
        let slot = Int(input[2+i])*4+i//64
        masks[slot] |= UInt64(1) << (i%64)
    var score = nr
    let top = UInt64(1) << ((n-1)%64)
    for i in range(m):
        let symbol = Int(input[2+n+i])
        var add = UInt64(0)
        var pc = UInt64(1)
        var mc = UInt64(0)
        for j in range(words):
            let eq = masks[symbol*4+j]
            let p = pv[j]
            let v = mv[j]
            let term = eq & p
            let limit = ~UInt64(0)
            let carry1 = p > limit-term
            var first = UInt64(0)
            if carry1: first = p-(limit-term)-1
            else: first = p+term
            let carry2 = add != 0 and first == limit
            var sum = UInt64(0)
            if not carry2: sum = first+add
            add = UInt64(1) if carry1 or carry2 else UInt64(0)
            let xh = (sum ^ p) | eq
            let xv = eq | v
            var ph = v | ~(xh | p)
            var mh = p & xh
            if j == words-1:
                if (ph & top) != 0: score += 1
                if (mh & top) != 0: score -= 1
            let next_pc = ph >> 63
            let next_mc = mh >> 63
            ph = (ph << 1) | pc
            mh = (mh << 1) | mc
            pc = next_pc
            mc = next_mc
            pv[j] = mh | ~(xv | ph)
            mv[j] = ph & xv
    return score
