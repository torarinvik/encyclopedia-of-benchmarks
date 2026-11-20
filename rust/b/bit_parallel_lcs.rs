//! Uncompiled multiword bit-parallel LCS length draft.
#[no_mangle]
pub unsafe extern "C" fn bit_parallel_lcs(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=515).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (nr, mr) = (values[0], values[1]);
    if !(0..=256).contains(&nr) || !(0..=256).contains(&mr) || length != (2+nr+mr) as usize { return -1; }
    if values[2..].iter().any(|v| !(0..=255).contains(v)) { return -1; }
    let (n, m) = (nr as usize, mr as usize);
    let mut masks = [[0u64;4];256];
    let mut row = [0u64;4];
    let words = (n+63)/64;
    for i in 0..n { masks[values[2+i] as usize][i/64] |= 1u64 << (i%64); }
    for i in 0..m {
        let symbol = values[2+n+i] as usize;
        let (mut carry, mut borrow) = (1u64, 0u64);
        for j in 0..words {
            let old = row[j];
            let combined = old | masks[symbol][j];
            let shifted = (old << 1) | carry;
            carry = old >> 63;
            let (partial, first_borrow) = combined.overflowing_sub(shifted);
            let (difference, second_borrow) = partial.overflowing_sub(borrow);
            borrow = u64::from(first_borrow || second_borrow);
            row[j] = combined & (combined ^ difference);
        }
    }
    row.iter().map(|word| i64::from(word.count_ones())).sum()
}
