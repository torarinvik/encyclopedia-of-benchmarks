const MAX_ITERATIONS: i64 = 10_000;
const MATRIX_ELEMENTS: usize = 16;

#[no_mangle]
pub unsafe extern "C" fn matmul_f64_4x4(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 1 { return -1; }
    let requested = unsafe { *input };
    if !(requested >= 1.0 && requested <= MAX_ITERATIONS as f64) || requested.fract() != 0.0 {
        return -1;
    }
    let iterations = requested as i64;

    const A: [[f64; 4]; 4] = [
        [4.5, 1.3, 6.0, 4.1], [2.5, 7.2, 7.7, 1.7],
        [6.7, 1.3, 9.4, 1.3], [1.1, 2.2, 3.0, 2.1],
    ];
    const B: [[f64; 4]; 4] = [
        [1.0, 7.9, 5.1, 3.4], [6.6, 2.8, 5.4, 9.2],
        [5.0, 4.1, 4.1, 9.9], [8.4, 3.7, 9.5, 6.4],
    ];
    let mut result = [0.0_f64; MATRIX_ELEMENTS];
    for _ in 0..iterations {
        for row in 0..4 {
            for column in 0..4 {
                let mut sum = A[row][0] * B[0][column];
                sum += A[row][1] * B[1][column];
                sum += A[row][2] * B[2][column];
                sum += A[row][3] * B[3][column];
                result[row * 4 + column] = sum;
            }
        }
    }
    if output.is_null() || output_capacity < MATRIX_ELEMENTS { return -2; }
    for index in 0..MATRIX_ELEMENTS { unsafe { *output.add(index) = result[index]; } }
    MATRIX_ELEMENTS as i64
}
