// Uncompiled multiword bit-vector global edit-distance draft.
@[export: 'myers_bitvector_edit_distance']
pub fn myers_bitvector_edit_distance(input &i64, length usize) i64 {
    if length < 2 || length > 515 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nr := input[0]; mr := input[1]
        if nr < 0 || nr > 256 || mr < 0 || mr > 256 || length != usize(2+nr+mr) { return -1 }
        n := int(nr); m := int(mr)
        for i in 2 .. int(length) { if input[i] < 0 || input[i] > 255 { return -1 } }
        if n == 0 { return mr }
        mut masks := [1024]u64{}
        mut pv := [4]u64{}
        mut mv := [4]u64{}
        words := (n+63)/64
        for j in 0 .. words { pv[j] = ~u64(0) }
        for i in 0 .. n { masks[int(input[2+i])*4+i/64] |= u64(1) << (i%64) }
        mut score := nr
        top := u64(1) << ((n-1)%64)
        for i in 0 .. m {
            symbol := int(input[2+n+i])
            mut add := u64(0); mut pc := u64(1); mut mc := u64(0)
            for j in 0 .. words {
                eq := masks[symbol*4+j]; p := pv[j]; v := mv[j]
                term := eq & p; limit := ~u64(0)
                carry1 := p > limit-term
                mut first := u64(0)
                if carry1 { first = p-(limit-term)-1 } else { first = p+term }
                carry2 := add != 0 && first == limit
                mut sum := u64(0)
                if !carry2 { sum = first+add }
                add = if carry1 || carry2 { u64(1) } else { u64(0) }
                xh := (sum ^ p) | eq; xv := eq | v
                mut ph := v | ~(xh | p); mut mh := p & xh
                if j == words-1 {
                    if ph & top != 0 { score++ }
                    if mh & top != 0 { score-- }
                }
                next_pc := ph >> 63; next_mc := mh >> 63
                ph = (ph << 1) | pc; mh = (mh << 1) | mc
                pc = next_pc; mc = next_mc
                pv[j] = mh | ~(xv | ph); mv[j] = ph & xv
            }
        }
        return score
    }
}
