const MAX_N: usize = 16;

#[no_mangle]
pub unsafe extern "C" fn minimum_area_rectangle_arbitrary_orientation(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > 34 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(4..=MAX_N as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != 1 + 2 * n { return -1; }

    let mut x = [0_i64; MAX_N];
    let mut y = [0_i64; MAX_N];
    for i in 0..n {
        x[i] = values[1 + 2 * i];
        y[i] = values[2 + 2 * i];
        if !(-32..=32).contains(&x[i]) || !(-32..=32).contains(&y[i]) { return -1; }
        for j in 0..i {
            if x[i] == x[j] && y[i] == y[j] { return -1; }
        }
    }

    let mut best = -1_i64;
    for i in 0..n {
        for j in i + 1..n {
            let (dx1, dy1) = (x[i] - x[j], y[i] - y[j]);
            let (mid_x, mid_y) = (x[i] + x[j], y[i] + y[j]);
            let length1 = dx1 * dx1 + dy1 * dy1;
            for k in 0..n {
                for l in k + 1..n {
                    if k < i || (k == i && l <= j) { continue; }
                    if k == i || k == j || l == i || l == j { continue; }
                    if mid_x != x[k] + x[l] || mid_y != y[k] + y[l] { continue; }
                    let (dx2, dy2) = (x[k] - x[l], y[k] - y[l]);
                    if length1 != dx2 * dx2 + dy2 * dy2 { continue; }
                    let area2 = (dx1 * dy2 - dy1 * dx2).abs();
                    if best < 0 || area2 < best { best = area2; }
                }
            }
        }
    }
    if best < 0 { 0 } else { best }
}
