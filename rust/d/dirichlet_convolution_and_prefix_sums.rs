const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 64;
const MAX_Q: usize = 15;
const MAX_PARSEABLE: usize = 32;
const MAX_OUTPUT_BYTES: usize = 120;

fn prefix_value(q: &[i64; MAX_Q], prefix: &[i64; MAX_Q], count: usize, value: i64) -> i64 {
    if value == 0 { return 0; }
    for i in 0..count {
        if q[i] == value { return prefix[i]; }
    }
    0
}

fn solve(input: &[i64], output: &mut [u8]) -> i64 {
    if input.len() < 3 || input.len() > MAX_PARSEABLE { return -1; }
    if !(1..=MAX_N as i64).contains(&input[0]) { return -1; }
    let n = input[0];
    let mut descending = [0i64; MAX_Q];
    let mut count = 0usize;
    let mut left = 1i64;
    while left <= n {
        let value = n / left;
        descending[count] = value;
        count += 1;
        left = n / value + 1;
    }
    let mut q = [0i64; MAX_Q];
    for i in 0..count { q[i] = descending[count - 1 - i]; }
    if input.len() != 1 + 2 * count { return -1; }

    let mut f = [0i64; MAX_Q];
    let mut g = [0i64; MAX_Q];
    let mut result = [0i64; MAX_Q];
    for i in 0..count {
        f[i] = input[1 + i];
        g[i] = input[1 + count + i];
        if !(1..MODULUS).contains(&f[i]) || !(1..MODULUS).contains(&g[i]) { return -1; }
    }
    let needed = 8 * count;
    if output.len() < needed { return -2; }

    for out in 0..count {
        let x = q[out];
        let mut total = 0i64;
        let mut start = 1i64;
        while start <= x {
            let quotient = x / start;
            let right = x / quotient;
            let below = x / (quotient + 1);
            let interval = (prefix_value(&q, &f, count, right)
                - prefix_value(&q, &f, count, below)).rem_euclid(MODULUS);
            let mut q_index = 0usize;
            while q_index < count && q[q_index] != quotient { q_index += 1; }
            if q_index == count { return -1; }
            total = (total + interval * g[q_index]) % MODULUS;
            start = right + 1;
        }
        result[out] = total;
    }
    for i in 0..count {
        for byte in 0..8 {
            output[8 * i + byte] = (result[i] as u64 >> (8 * byte)) as u8;
        }
    }
    needed as i64
}

#[no_mangle]
pub unsafe extern "C" fn dirichlet_convolution_and_prefix_sums(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if output.is_null() {
        let mut scratch = [0u8; MAX_OUTPUT_BYTES];
        let status = solve(values, &mut scratch);
        return if status < 0 { status } else { -2 };
    }
    let bytes = std::slice::from_raw_parts_mut(output, output_capacity.min(MAX_OUTPUT_BYTES));
    solve(values, bytes)
}
