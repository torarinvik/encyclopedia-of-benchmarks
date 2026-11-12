const MAX_N: i64 = 1_000_000_000_000_000_000;
const MAX_T: usize = 8;
const MAX_K: i64 = 8;
const WIDTH: usize = 9;

fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

fn stirling_value(n: i64, k: usize, modulus: i64) -> i64 {
    let dimension = k + 1;
    let mut matrix = [0_i64; WIDTH * WIDTH];
    let mut squared = [0_i64; WIDTH * WIDTH];
    let mut vector = [0_i64; WIDTH];
    let mut next_vector = [0_i64; WIDTH];
    for index in 0..dimension {
        matrix[index * WIDTH + index] = index as i64 % modulus;
        if index > 0 {
            matrix[index * WIDTH + index - 1] = 1;
        }
    }
    vector[0] = 1;

    let mut exponent = n;
    while exponent > 0 {
        if exponent % 2 != 0 {
            for row in 0..dimension {
                let mut total = 0_i64;
                for column in 0..dimension {
                    total = (total + matrix[row * WIDTH + column] * vector[column]) % modulus;
                }
                next_vector[row] = total;
            }
            for row in 0..dimension {
                vector[row] = next_vector[row];
            }
        }
        exponent /= 2;
        if exponent > 0 {
            for row in 0..dimension {
                for column in 0..dimension {
                    let mut total = 0_i64;
                    for inner in 0..dimension {
                        total = (total + matrix[row * WIDTH + inner] * matrix[inner * WIDTH + column]) % modulus;
                    }
                    squared[row * WIDTH + column] = total;
                }
            }
            for row in 0..dimension {
                for column in 0..dimension {
                    matrix[row * WIDTH + column] = squared[row * WIDTH + column];
                    squared[row * WIDTH + column] = 0;
                }
            }
        }
    }
    vector[k]
}

#[no_mangle]
pub unsafe extern "C" fn stirling_number_of_the_second_kind_small_p_large_n(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 2 + 2 * MAX_T {
        return -1;
    }
    let count_value = *input;
    let modulus = *input.add(1);
    if count_value < 1 || count_value > MAX_T as i64
        || length != (2 + 2 * count_value) as usize
        || modulus < 11 || modulus > 97 || !is_prime(modulus)
    {
        return -1;
    }

    let mut result = 0_i64;
    for case_index in 0..count_value as usize {
        let n = *input.add(2 + 2 * case_index);
        let k_value = *input.add(3 + 2 * case_index);
        if n < 0 || n > MAX_N || k_value < 0 || k_value > MAX_K || k_value > n {
            return -1;
        }
        let value = stirling_value(n, k_value as usize, modulus);
        let next = (case_index + 1) as i64;
        result = (result + next * next * value) % modulus;
    }
    result
}
