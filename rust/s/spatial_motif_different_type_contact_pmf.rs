const MAX_LENGTH: i64 = 10;
const MAX_SUPPORT: usize = 11;

fn choose(total: i64, selected: i64) -> i64 {
    if total < 0 || selected < 0 || selected > total { return 0; }
    let k = selected.min(total - selected);
    let mut value = 1i64;
    for factor in 1..=k { value = value * (total - k + factor) / factor; }
    value
}

fn multinomial3(total: i64, first: i64, second: i64) -> i64 {
    if total < 0 || first < 0 || second < 0 || first > total || second > total
        || first + second > total { return 0; }
    choose(total, first) * choose(total - first, second)
}

fn gcd(mut left: i64, mut right: i64) -> i64 {
    while right != 0 { let remainder = left % right; left = right; right = remainder; }
    left
}

fn write_word(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn spatial_motif_different_type_contact_pmf(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 5 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, x10, y10, x20, y20) = (values[0], values[1], values[2], values[3], values[4]);
    if !(1..=MAX_LENGTH).contains(&n0) || x10 < 0 || y10 < 0 || x20 < 0 || y20 < 0
        || x10 > n0 || y10 > n0 || x20 > n0 || y20 > n0 { return -1; }
    if x10 + y10 > n0 || x20 + y20 > n0 { return -1; }

    let n = n0 as usize;
    let x1 = x10 as usize;
    let y1 = y10 as usize;
    let x2 = x20 as usize;
    let y2 = y20 as usize;
    let denominator = multinomial3(n0, x20, y20);
    let mut counts = [0i64; MAX_SUPPORT];

    for contacts in 0..=n {
        for xx in 0..=x1 {
            for xy in 0..=x1 - xx {
                let yx = contacts as i64 - xy as i64;
                if yx < 0 || yx > y10 { continue; }
                for yy in 0..=(y1 - yx as usize) {
                    counts[contacts] += multinomial3(x10, xx as i64, xy as i64)
                        * multinomial3(y10, yx, yy as i64)
                        * multinomial3(n0 - x10 - y10,
                                      x20 - xx as i64 - yx,
                                      y20 - xy as i64 - yy as i64);
                }
            }
        }
    }

    let mean_numerator = (0..=n).map(|m| m as i64 * counts[m]).sum::<i64>();
    let mut reduced_numerator = mean_numerator;
    let mut reduced_denominator = denominator;
    let divisor = gcd(reduced_numerator, reduced_denominator);
    reduced_numerator /= divisor;
    reduced_denominator /= divisor;
    let bytes = (n + 5) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let output = std::slice::from_raw_parts_mut(output, bytes);
    write_word(output, 0, n0);
    write_word(output, 1, denominator);
    for m in 0..=n { write_word(output, 2 + m, counts[m]); }
    write_word(output, n + 3, reduced_numerator);
    write_word(output, n + 4, reduced_denominator);
    bytes as i64
}
