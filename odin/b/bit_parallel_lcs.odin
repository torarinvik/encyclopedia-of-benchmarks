// Uncompiled multiword bit-parallel LCS length draft.
package bit_parallel_lcs
import "core:c"
@(export)
bit_parallel_lcs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 515 do return -1
    nr, mr := input[0], input[1]
    if nr < 0 || nr > 256 || mr < 0 || mr > 256 || length != c.size_t(2+nr+mr) do return -1
    n, m := int(nr), int(mr)
    for i := 2; i < int(length); i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
    masks: [256][4]u64 = {}
    row: [4]u64 = {}
    words := (n+63)/64
    for i := 0; i < n; i += 1 { masks[int(input[2+i])][i/64] |= u64(1) << uint(i%64) }
    for i := 0; i < m; i += 1 {
        symbol := int(input[2+n+i])
        carry, borrow := u64(1), u64(0)
        for j := 0; j < words; j += 1 {
            old := row[j]; combined := old | masks[symbol][j]
            shifted := (old << 1) | carry; carry = old >> 63
            first_borrow := combined < shifted
            partial: u64
            if first_borrow { partial = ~(shifted-combined)+1 } else { partial = combined-shifted }
            second_borrow := partial < borrow
            difference: u64
            if second_borrow { difference = ~u64(0) } else { difference = partial-borrow }
            borrow = 0
            if first_borrow || second_borrow { borrow = 1 }
            row[j] = combined & (combined ~ difference)
        }
    }
    result: i64 = 0
    for j := 0; j < words; j += 1 {
        word := row[j]
        for word != 0 { word &= word-1; result += 1 }
    }
    return result
}
