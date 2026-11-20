// Uncompiled multiword bit-vector global edit-distance draft.
package myers_bitvector_edit_distance
import "core:c"
@(export)
myers_bitvector_edit_distance :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 515 do return -1
    nr, mr := input[0], input[1]
    if nr < 0 || nr > 256 || mr < 0 || mr > 256 || length != c.size_t(2+nr+mr) do return -1
    n, m := int(nr), int(mr)
    for i := 2; i < int(length); i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
    if n == 0 do return mr
    masks: [256][4]u64 = {}
    pv, mv: [4]u64
    words := (n+63)/64
    for j := 0; j < words; j += 1 { pv[j] = ~u64(0); mv[j] = 0 }
    for i := 0; i < n; i += 1 { masks[int(input[2+i])][i/64] |= u64(1) << uint(i%64) }
    score := nr
    top := u64(1) << uint((n-1)%64)
    for i := 0; i < m; i += 1 {
        symbol := int(input[2+n+i])
        add, pc, mc := u64(0), u64(1), u64(0)
        for j := 0; j < words; j += 1 {
            eq, p, v := masks[symbol][j], pv[j], mv[j]
            term := eq & p
            limit := ~u64(0)
            carry1 := p > limit-term
            first: u64
            if carry1 { first = p-(limit-term)-1 } else { first = p+term }
            carry2 := add != 0 && first == limit
            sum: u64
            if carry2 { sum = 0 } else { sum = first+add }
            add = 0
            if carry1 || carry2 { add = 1 }
            xh := (sum ~ p) | eq
            xv := eq | v
            ph, mh := v | ~(xh | p), p & xh
            if j == words-1 {
                if ph & top != 0 { score += 1 }
                if mh & top != 0 { score -= 1 }
            }
            next_pc, next_mc := ph >> 63, mh >> 63
            ph = (ph << 1) | pc; mh = (mh << 1) | mc
            pc = next_pc; mc = next_mc
            pv[j] = mh | ~(xv | ph); mv[j] = ph & xv
        }
    }
    return score
}
