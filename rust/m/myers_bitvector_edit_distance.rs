//! Uncompiled multiword bit-vector global edit-distance draft.
#[no_mangle]
pub unsafe extern "C" fn myers_bitvector_edit_distance(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=515).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (nr, mr) = (values[0], values[1]);
    if !(0..=256).contains(&nr) || !(0..=256).contains(&mr)
        || length != (2+nr+mr) as usize { return -1; }
    if values[2..].iter().any(|v| !(0..=255).contains(v)) { return -1; }
    let (n, m) = (nr as usize, mr as usize);
    if n == 0 { return mr; }
    let mut masks = [[0u64;4];256];
    let mut pv = [u64::MAX;4];
    let mut mv = [0u64;4];
    let words = (n+63)/64;
    for i in 0..n { masks[values[2+i] as usize][i/64] |= 1u64 << (i%64); }
    let mut score = nr;
    let top = 1u64 << ((n-1)%64);
    for i in 0..m {
        let symbol = values[2+n+i] as usize;
        let (mut add_carry, mut ph_carry, mut mh_carry) = (0u64, 1u64, 0u64);
        for j in 0..words {
            let (eq, p, v) = (masks[symbol][j], pv[j], mv[j]);
            let (first, carry1) = (eq & p).overflowing_add(p);
            let (sum, carry2) = first.overflowing_add(add_carry);
            add_carry = u64::from(carry1 || carry2);
            let xh = (sum ^ p) | eq;
            let xv = eq | v;
            let mut ph = v | !(xh | p);
            let mut mh = p & xh;
            if j == words-1 {
                if ph & top != 0 { score += 1; }
                if mh & top != 0 { score -= 1; }
            }
            let (next_ph, next_mh) = (ph >> 63, mh >> 63);
            ph = (ph << 1) | ph_carry;
            mh = (mh << 1) | mh_carry;
            ph_carry = next_ph; mh_carry = next_mh;
            pv[j] = mh | !(xv | ph);
            mv[j] = ph & xv;
        }
    }
    score
}
