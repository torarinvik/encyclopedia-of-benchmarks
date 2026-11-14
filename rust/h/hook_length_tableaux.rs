// Independent hook-length count; see package README.
const P: i64 = 998_244_353;

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent != 0 {
        if exponent & 1 != 0 { result = result * base % P; }
        base = base * base % P;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn hook_length_tableaux(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 { return -1; }
    let count = *input;
    if !(0..=65536).contains(&count) || length != count as usize + 1 { return -1; }
    let shape = std::slice::from_raw_parts(input.add(1), count as usize);
    let mut total = 0i64;
    let mut previous = 1_000_000;
    for &width in shape {
        if width < 1 || width > previous { return -1; }
        total += width;
        if total > 1_000_000 { return -1; }
        previous = width;
    }
    let mut hooks = 1i64;
    let mut height = shape.len();
    if !shape.is_empty() {
        for column in 0..shape[0] {
            while height > 0 && shape[height - 1] <= column { height -= 1; }
            for row in 0..height {
                let hook = shape[row] - column + (height - row - 1) as i64;
                hooks = hooks * hook % P;
            }
        }
    }
    let mut factorial = 1;
    for n in 2..=total { factorial = factorial * n % P; }
    factorial * power(hooks, P - 2) % P
}
