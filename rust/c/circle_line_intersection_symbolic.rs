//! Independently authored draft; not compiled or run.
#[no_mangle]
pub unsafe extern "C" fn circle_line_intersection_symbolic(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 6 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, 6) };
    if values.iter().any(|v| !(-1000..=1000).contains(v)) { return -1; }
    let (x, y, r, a, b, c) = (values[0], values[1], values[2], values[3], values[4], values[5]);
    if r < 1 || (a == 0 && b == 0) { return -1; }
    let d = a*a+b*b;
    let q = a*x+b*y+c;
    let h = r*r*d-q*q;
    let words = [if h < 0 { 0 } else if h == 0 { 1 } else { 2 },
                 x*d-a*q, y*d-b*q, d, -b, a, h];
    let count = if h < 0 { 1 } else { 7 };
    let needed = 8*count;
    if output.is_null() || capacity < needed { return -2; }
    let bytes = unsafe { std::slice::from_raw_parts_mut(output, needed) };
    for (i, word) in words[..count].iter().enumerate() {
        bytes[8*i..8*i+8].copy_from_slice(&word.to_le_bytes());
    }
    needed as i64
}
