// Zhouge sieve for f(p^e) = a*e + b*p modulo 469762049.
const MODULUS: i64 = 469_762_049;
const MAX_N: i64 = 10_000_000;

fn floor_sqrt(value: i64) -> i64 {
    let (mut low, mut high) = (1i64, 3162i64);
    while low < high {
        let middle = low + (high - low + 1) / 2;
        if middle <= value / middle { low = middle; } else { high = middle - 1; }
    }
    low
}

fn normalize(value: i64) -> i64 {
    let remainder = value % MODULUS;
    if remainder < 0 { remainder + MODULUS } else { remainder }
}

fn quotient_at(index: usize, n: i64, high_count: usize, size: usize) -> i64 {
    if index < high_count { n / index as i64 } else { (size - index) as i64 }
}

fn value_index(value: i64, n: i64, root: i64, size: usize) -> usize {
    if value <= root { size - value as usize } else { (n / value) as usize }
}

fn apply_skipped_prime_range(
    index: usize,
    stage: usize,
    small_lo: &[u32],
    small_hi: &[u32],
    simple_cursor: &mut [u32],
    prefix_g: &[i64],
    smooth_sum: &mut [i64],
) {
    let next = ((stage + 1) as u32).max(small_lo[index]).min(small_hi[index]);
    let old = simple_cursor[index];
    if next < old {
        smooth_sum[index] = normalize(smooth_sum[index] + prefix_g[old as usize] - prefix_g[next as usize]);
        simple_cursor[index] = next;
    }
}

fn apply_skipped_power_sums(
    index: usize,
    stage: usize,
    small_lo: &[u32],
    small_hi: &[u32],
    g_cursor: &mut [u32],
    prefix_sum: &[i64],
    g_zero: &mut [i64],
    g_one: &mut [i64],
) {
    let next = (stage as u32).max(small_lo[index]).min(small_hi[index]);
    let old = g_cursor[index];
    if next > old {
        g_zero[index] = normalize(g_zero[index] - (next - old) as i64);
        g_one[index] = normalize(g_one[index] - (prefix_sum[next as usize] - prefix_sum[old as usize]));
        g_cursor[index] = next;
    }
}

fn small_value(mut value: i64, smallest: &[u32], a: i64, b: i64) -> i64 {
    let mut result = 1i64;
    while value > 1 {
        let prime = smallest[value as usize] as i64;
        let mut exponent = 0i64;
        loop {
            value /= prime;
            exponent += 1;
            if value <= 1 || value % prime != 0 { break; }
        }
        result = result * ((a * exponent + b * prime) % MODULUS) % MODULUS;
    }
    result
}

fn solve(n: i64, a: i64, b: i64) -> i64 {
    let root = floor_sqrt(n);
    let mut high_count = (n / root) as usize;
    while high_count > 1 && n / (high_count - 1) as i64 == root { high_count -= 1; }
    let size = high_count + root as usize;

    let mut smallest = vec![0u32; root as usize + 1];
    let mut primes = Vec::<i64>::with_capacity(root as usize + 1);
    for value in 2..=root {
        if smallest[value as usize] != 0 { continue; }
        smallest[value as usize] = value as u32;
        primes.push(value);
        if value <= root / value {
            let mut multiple = value * value;
            while multiple <= root {
                let factor = &mut smallest[multiple as usize];
                if *factor == 0 { *factor = value as u32; }
                multiple += value;
            }
        }
    }

    let mut prefix_sum = vec![0i64; primes.len() + 1];
    let mut prefix_g = vec![0i64; primes.len() + 1];
    for (index, &prime) in primes.iter().enumerate() {
        prefix_sum[index + 1] = normalize(prefix_sum[index] + prime);
        prefix_g[index + 1] = normalize(prefix_g[index] + a + b * prime);
    }

    let mut g_zero = vec![0i64; size];
    let mut g_one = vec![0i64; size];
    let mut smooth_sum = vec![1i64; size];
    let mut small_lo = vec![0u32; size];
    let mut small_hi = vec![0u32; size];
    let mut simple_cursor = vec![0u32; size];
    let mut g_cursor = vec![0u32; size];
    for index in 1..size {
        let value = quotient_at(index, n, high_count, size);
        let lo = primes.partition_point(|&prime| prime <= floor_sqrt(value));
        let hi = primes.partition_point(|&prime| prime <= value);
        small_lo[index] = lo as u32;
        small_hi[index] = hi as u32;
        simple_cursor[index] = hi as u32;
        g_cursor[index] = lo as u32;
        g_zero[index] = value % MODULUS;
        let (mut left, mut right) = (value, value + 1);
        if left & 1 == 0 { left /= 2; } else { right /= 2; }
        g_one[index] = (left % MODULUS) * (right % MODULUS) % MODULUS;
    }

    for (stage, &prime) in primes.iter().enumerate() {
        let square = prime * prime;
        for index in 1..size {
            let value = quotient_at(index, n, high_count, size);
            if value < square { break; }
            let child = value_index(value / prime, n, root, size);
            apply_skipped_power_sums(child, stage, &small_lo, &small_hi, &mut g_cursor,
                                     &prefix_sum, &mut g_zero, &mut g_one);
            g_zero[index] = normalize(g_zero[index] - g_zero[child]);
            g_one[index] = normalize(g_one[index] - prime * g_one[child]);
        }
    }
    for index in 1..size {
        apply_skipped_power_sums(index, primes.len(), &small_lo, &small_hi, &mut g_cursor,
                                 &prefix_sum, &mut g_zero, &mut g_one);
    }

    for stage in (0..primes.len()).rev() {
        let prime = primes[stage];
        let square = prime * prime;
        for index in 1..size {
            let value = quotient_at(index, n, high_count, size);
            if value < square { break; }
            apply_skipped_prime_range(index, stage, &small_lo, &small_hi,
                                      &mut simple_cursor, &prefix_g, &mut smooth_sum);
            let mut power = prime;
            let mut exponent = 1i64;
            while power <= value {
                let child = value_index(value / power, n, root, size);
                apply_skipped_prime_range(child, stage, &small_lo, &small_hi,
                                          &mut simple_cursor, &prefix_g, &mut smooth_sum);
                let local = (a * exponent + b * prime) % MODULUS;
                smooth_sum[index] = normalize(smooth_sum[index] + local * smooth_sum[child]);
                power *= prime;
                exponent += 1;
            }
        }
    }

    let mut answer = smooth_sum[1];
    for value in 1..=root {
        let quotient_index = value_index(n / value, n, root, size);
        let large_prime_sum = normalize(
            a * normalize(g_zero[quotient_index] - 1) +
            b * normalize(g_one[quotient_index] - 1),
        );
        answer = normalize(answer + small_value(value, &smallest, a, b) * large_prime_sum);
    }
    answer
}

#[no_mangle]
pub unsafe extern "C" fn zhouge_summatory_multiplicative_function(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let [n, a, b] = [values[0], values[1], values[2]];
    if !(1..=MAX_N).contains(&n) || !(0..MODULUS).contains(&a) || !(0..MODULUS).contains(&b) {
        return -1;
    }
    solve(n, a, b)
}
