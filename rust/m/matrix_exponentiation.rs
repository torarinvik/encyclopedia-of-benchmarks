const MAX_ORDER: usize = 8;
const MAX_INPUT_WORDS: usize = 18;
const MOD: i64 = 1_000_000_007;
const MAX_N: i64 = 1_000_000_000_000;

#[derive(Clone, Copy, Default)]
struct Matrix { cell: [[i64; MAX_ORDER]; MAX_ORDER] }

fn multiply(left: Matrix, right: Matrix, order: usize) -> Matrix {
    let mut result = Matrix::default();
    for row in 0..order {
        for col in 0..order {
            for inner in 0..order {
                result.cell[row][col] = (result.cell[row][col] + (left.cell[row][inner] * right.cell[inner][col]) % MOD) % MOD;
            }
        }
    }
    result
}
fn power(matrix: Matrix, exponent: i64, order: usize) -> Matrix {
    if exponent == 1 { return matrix; }
    if exponent % 2 == 1 { return multiply(matrix, power(matrix, exponent - 1, order), order); }
    let half = power(matrix, exponent / 2, order);
    multiply(half, half, order)
}

#[no_mangle]
pub unsafe extern "C" fn matrix_exponentiation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_WORDS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let order_raw = values[0];
    if !(1..=MAX_ORDER as i64).contains(&order_raw) || length != (2 * order_raw + 2) as usize { return -1; }
    let order = order_raw as usize;
    if values[1..1 + 2 * order].iter().any(|&value| !(0..MOD).contains(&value)) { return -1; }
    let n = values[2 * order + 1];
    if !(0..=MAX_N).contains(&n) { return -1; }
    if n == 0 { return 0; }
    if n <= order_raw { return values[n as usize]; }
    let mut transition = Matrix::default();
    for i in 0..order.saturating_sub(1) { transition.cell[i][i + 1] = 1; }
    for col in 0..order { transition.cell[order - 1][col] = values[order + 1 + order - 1 - col]; }
    transition = power(transition, n - 1, order);
    let mut result = 0i64;
    for i in 0..order { result = (result + (transition.cell[0][i] * values[1 + i]) % MOD) % MOD; }
    result
}
