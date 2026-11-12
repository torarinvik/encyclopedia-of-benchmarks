/// Finite geometric power sum by binary composition of moment blocks.
const MODULUS: i64 = 998_244_353;
const MAX_DEGREE: usize = 32;
type Moments = [i64; MAX_DEGREE + 1];
type Binomials = [[i64; MAX_DEGREE + 1]; MAX_DEGREE + 1];

fn sepm_shift(source: &Moments, shift: u64, degree: usize, choose: &Binomials) -> Moments {
    let mut powers = [0_i64; MAX_DEGREE + 1];
    let mut destination = [0_i64; MAX_DEGREE + 1];
    powers[0] = 1;
    let reduced_shift = (shift % MODULUS as u64) as i64;
    for i in 1..=degree { powers[i] = powers[i - 1] * reduced_shift % MODULUS; }
    for d in 0..=degree {
        let mut total = 0_i64;
        for k in 0..=d {
            let term = choose[d][k] * powers[d - k] % MODULUS;
            total = (total + term * source[k]) % MODULUS;
        }
        destination[d] = total;
    }
    destination
}

#[no_mangle]
pub extern "C" fn sum_of_exponential_times_polynomial(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let r = values[0];
    let degree_value = values[1];
    let n_value = values[2];
    if r < 0 || r >= MODULUS || degree_value < 0 || degree_value > MAX_DEGREE as i64 ||
        n_value < 0 || n_value > 1_000_000_000_000_000_000 { return -1; }
    let degree = degree_value as usize;
    let mut choose: Binomials = [[0_i64; MAX_DEGREE + 1]; MAX_DEGREE + 1];
    choose[0][0] = 1;
    for d in 1..=degree {
        choose[d][0] = 1;
        choose[d][d] = 1;
        for k in 1..d { choose[d][k] = (choose[d - 1][k - 1] + choose[d - 1][k]) % MODULUS; }
    }

    let mut accumulated = [0_i64; MAX_DEGREE + 1];
    let mut block = [0_i64; MAX_DEGREE + 1];
    block[0] = 1;
    let mut accumulated_power = 1_i64;
    let mut block_power = r;
    let mut accumulated_length = 0_u64;
    let mut block_length = 1_u64;
    let mut remaining = n_value as u64;
    while remaining > 0 {
        if remaining & 1 != 0 {
            let shifted = sepm_shift(&block, accumulated_length, degree, &choose);
            for d in 0..=degree {
                accumulated[d] = (accumulated[d] + accumulated_power * shifted[d]) % MODULUS;
            }
            accumulated_power = accumulated_power * block_power % MODULUS;
            accumulated_length += block_length;
        }
        let shifted = sepm_shift(&block, block_length, degree, &choose);
        for d in 0..=degree { block[d] = (block[d] + block_power * shifted[d]) % MODULUS; }
        block_power = block_power * block_power % MODULUS;
        block_length <<= 1;
        remaining >>= 1;
    }
    accumulated[degree]
}
