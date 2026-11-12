const MODULUS: i64 = 469_762_049;
const MAX_N: i64 = 100_000_000;

fn floor_sqrt(value: i64) -> i64 {
    let (mut low, mut high) = (1i64, 31_623i64);
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

fn triangular_mod(value: i64) -> i64 {
    let (mut left, mut right) = (value, value + 1);
    if left & 1 == 0 { left /= 2; } else { right /= 2; }
    ((left % MODULUS) * (right % MODULUS)) % MODULUS
}

fn value_index(value: i64, n: i64, root: i64, size: usize) -> usize {
    if value <= root { size - value as usize } else { (n / value) as usize }
}

fn solve(n: i64, a: i64, b: i64) -> i64 {
    let root = floor_sqrt(n);
    let mut high_count = (n / root) as usize;
    while high_count > 1 && n / (high_count - 1) as i64 == root { high_count -= 1; }
    let size = high_count + root as usize;
    let mut quotients = vec![0i64; size];
    let mut prime_count = vec![0i64; size];
    let mut prime_sum = vec![0i64; size];
    for index in 1..high_count { quotients[index] = n / index as i64; }
    for value in 1..=root { quotients[size - value as usize] = value; }

    let mut composite = vec![false; root as usize + 1];
    let mut primes = Vec::new();
    for value in 2..=root {
        if composite[value as usize] { continue; }
        primes.push(value);
        if value <= root / value {
            let mut multiple = value * value;
            while multiple <= root {
                composite[multiple as usize] = true;
                multiple += value;
            }
        }
    }

    for index in 1..size {
        prime_count[index] = quotients[index] - 1;
        prime_sum[index] = normalize(triangular_mod(quotients[index]) - 1);
    }
    let (mut preceding_count, mut preceding_sum) = (0i64, 0i64);
    for &prime in &primes {
        let square = prime * prime;
        for index in 1..size {
            if quotients[index] < square { break; }
            let quotient_index = value_index(quotients[index] / prime, n, root, size);
            prime_count[index] -= prime_count[quotient_index] - preceding_count;
            let sum_delta = normalize(prime_sum[quotient_index] - preceding_sum);
            prime_sum[index] = normalize(prime_sum[index] - (prime % MODULUS) * sum_delta);
        }
        preceding_count += 1;
        preceding_sum = normalize(preceding_sum + prime);
    }

    let mut prime_f = vec![0i64; size];
    for index in 1..size {
        prime_f[index] = (a * (prime_count[index] % MODULUS) + b * prime_sum[index]) % MODULUS;
    }
    let mut values = prime_f.clone();
    let mut next_values = prime_f.clone();
    for position in (0..primes.len()).rev() {
        let prime = primes[position];
        let mut power = prime;
        let mut exponent = 1i64;
        let prime_prefix = prime_f[value_index(prime, n, root, size)];
        while n / prime >= power {
            let local = (a * exponent + b * prime) % MODULUS;
            let next_local = (a * (exponent + 1) + b * prime) % MODULUS;
            let next_power = power * prime;
            for index in 1..size {
                if next_power > quotients[index] { break; }
                let quotient_index = value_index(quotients[index] / power, n, root, size);
                let non_prime_sum = normalize(values[quotient_index] - prime_prefix);
                next_values[index] = normalize(next_values[index] + local * non_prime_sum + next_local);
            }
            power = next_power;
            exponent += 1;
        }
        let copied = (value_index(prime * prime, n, root, size) + 1).min(size);
        values[..copied].copy_from_slice(&next_values[..copied]);
    }
    normalize(values[value_index(n, n, root, size)] + 1)
}

/// Packed input `[N, a, b]`; return the summatory multiplicative value modulo 469762049.
#[no_mangle]
pub unsafe extern "C" fn sum_of_multiplicative_function_large(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let n = *input;
    let a = *input.add(1);
    let b = *input.add(2);
    if !(1..=MAX_N).contains(&n) || !(0..MODULUS).contains(&a) || !(0..MODULUS).contains(&b) {
        return -1;
    }
    solve(n, a, b)
}
