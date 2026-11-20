// Uncompiled multiword bit-parallel LCS length draft.
@[export: 'bit_parallel_lcs']
pub fn bit_parallel_lcs(input &i64, length usize) i64 {
    if length < 2 || length > 515 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nr := input[0]; mr := input[1]
        if nr < 0 || nr > 256 || mr < 0 || mr > 256 || length != usize(2+nr+mr) { return -1 }
        n := int(nr); m := int(mr)
        for i in 2 .. int(length) { if input[i] < 0 || input[i] > 255 { return -1 } }
        mut masks := [1024]u64{}
        mut row := [4]u64{}
        words := (n+63)/64
        for i in 0 .. n {
            slot := int(input[2+i])*4+i/64
            masks[slot] |= u64(1) << (i%64)
        }
        for i in 0 .. m {
            symbol := int(input[2+n+i])
            mut carry := u64(1)
            mut borrow := u64(0)
            for j in 0 .. words {
                old := row[j]; combined := old | masks[symbol*4+j]
                shifted := (old << 1) | carry; carry = old >> 63
                first_borrow := combined < shifted
                mut partial := u64(0)
                if first_borrow { partial = ~(shifted-combined)+1 } else { partial = combined-shifted }
                second_borrow := partial < borrow
                mut difference := u64(0)
                if second_borrow { difference = ~u64(0) } else { difference = partial-borrow }
                borrow = if first_borrow || second_borrow { u64(1) } else { u64(0) }
                row[j] = combined & (combined ^ difference)
            }
        }
        mut result := i64(0)
        for j in 0 .. words {
            mut word := row[j]
            for word != 0 { word &= word-1; result++ }
        }
        return result
    }
}
