const MAX_N: usize = 8;
const MAX_INPUT: usize = 259;

#[no_mangle]
pub unsafe extern "C" fn freivalds_matrix_product_verification(
    input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n64 = words[0];
    let rounds64 = words[1];
    if !(1..=8).contains(&n64) || !(1..=8).contains(&rounds64) { return -1; }
    let n = n64 as usize;
    let rounds = rounds64 as usize;
    let matrix_words = n * n;
    if length != 2 + 3 * matrix_words + rounds * n { return -1; }
    if words[2..2 + 3 * matrix_words].iter().any(|&x| !(-3..=3).contains(&x)) { return -1; }
    let signs_offset = 2 + 3 * matrix_words;
    if words[signs_offset..].iter().any(|&x| x != -1 && x != 1) { return -1; }

    let mut bx = [0i64; MAX_N];
    let mut abx = [0i64; MAX_N];
    let mut cx = [0i64; MAX_N];
    for round in 0..rounds {
        for row in 0..n {
            let mut sum = 0i64;
            for col in 0..n {
                sum += words[2 + matrix_words + row * n + col]
                    * words[signs_offset + round * n + col];
            }
            bx[row] = sum;
        }
        for row in 0..n {
            let mut left = 0i64;
            let mut right = 0i64;
            for col in 0..n {
                left += words[2 + row * n + col] * bx[col];
                right += words[2 + 2 * matrix_words + row * n + col]
                    * words[signs_offset + round * n + col];
            }
            abx[row] = left;
            cx[row] = right;
        }
        for row in 0..n { if abx[row] != cx[row] { return 0; } }
    }
    1
}
