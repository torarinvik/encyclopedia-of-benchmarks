/// Return the zero-based 5-smooth number at index n.
#[no_mangle]
pub extern "C" fn nth_ugly_number(n: i64) -> i64 {
    if !(0..=12_690).contains(&n) {
        return -1;
    }
    let mut values = [0_i64; 12_691];
    values[0] = 1;
    let (mut i2, mut i3, mut i5) = (0usize, 0usize, 0usize);
    for index in 1..=n as usize {
        let c2 = 2 * values[i2];
        let c3 = 3 * values[i3];
        let c5 = 5 * values[i5];
        let next = c2.min(c3).min(c5);
        values[index] = next;
        if c2 == next { i2 += 1; }
        if c3 == next { i3 += 1; }
        if c5 == next { i5 += 1; }
    }
    values[n as usize]
}
