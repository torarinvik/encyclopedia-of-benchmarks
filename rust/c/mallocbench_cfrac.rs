/*
 * Clean-room bounded CFRAC profile based on the published
 * Morrison-Brillhart continued-fraction factorization method.
 * No code from the restricted arbitrary-precision package is included.
 */
const MAX_BASE: usize = 10;
const MAX_ITERATIONS: usize = 48;
const MAX_PRIME: u32 = 10000;

fn gcd(mut a: u64, mut b: u64) -> u64 {
    while b != 0 { let r = a % b; a = b; b = r; }
    a
}

fn modpow(mut base: u64, mut exponent: u64, modulus: u64) -> u64 {
    let mut result = 1;
    base %= modulus;
    while exponent != 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus; }
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    result
}

fn is_prime(value: u32) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2;
    while u64::from(divisor) * u64::from(divisor) <= u64::from(value) {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn make_base(n: u64, requested: usize, base: &mut [u32; MAX_BASE]) -> bool {
    let mut count = 1;
    base[0] = 2;
    let mut p = 3;
    while p <= MAX_PRIME && count < requested {
        if is_prime(p) {
            let residue = modpow(n % u64::from(p), u64::from((p - 1) / 2), u64::from(p));
            // Upstream selects residue zero too; this profile rejects that domain case.
            if residue == 0 { return false; }
            if residue == 1 {
                base[count] = p;
                count += 1;
            }
        }
        p += 2;
    }
    count == requested
}

fn dependency_factor(n: u64, selected: u64, relation_count: usize,
    relation_a: &[u64; MAX_ITERATIONS], relation_exp: &[[u8; MAX_BASE]; MAX_ITERATIONS],
    base: &[u32; MAX_BASE], base_count: usize) -> i64 {
    let mut x = 1_u64;
    let mut exponent_sum = [0_u64; MAX_BASE];
    for i in 0..relation_count {
        if selected & (1_u64 << i) == 0 { continue; }
        x = (x * relation_a[i]) % n;
        for j in 0..base_count { exponent_sum[j] += u64::from(relation_exp[i][j]); }
    }
    let mut y = 1_u64;
    for j in 0..base_count { y = (y * modpow(u64::from(base[j]), exponent_sum[j] / 2, n)) % n; }
    let minus = gcd(x.abs_diff(y), n);
    if minus > 1 && minus < n { return minus as i64; }
    let plus = gcd(x + y, n);
    if plus > 1 && plus < n { return plus as i64; }
    0
}

#[no_mangle]
pub unsafe extern "C" fn mallocbench_cfrac(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, base_value, iteration_value) = (values[0], values[1], values[2]);
    if !(15..=1_000_000).contains(&n_value) || n_value & 1 == 0 ||
        !(2..=MAX_BASE as i64).contains(&base_value) ||
        !(1..=MAX_ITERATIONS as i64).contains(&iteration_value) { return -1; }
    let n = n_value as u64;
    let mut root = 0_u64;
    while root + 1 <= n / (root + 1) { root += 1; }
    if root * root == n { return -1; }
    let base_count = base_value as usize;
    let iteration_limit = iteration_value as usize;
    let mut base = [0_u32; MAX_BASE];
    if !make_base(n, base_count, &mut base) { return -1; }

    let mut basis_vector = [0_u64; MAX_BASE + 1];
    let mut basis_combo = [0_u64; MAX_BASE + 1];
    let mut basis_used = [false; MAX_BASE + 1];
    let mut relation_a = [0_u64; MAX_ITERATIONS];
    let mut relation_exp = [[0_u8; MAX_BASE]; MAX_ITERATIONS];
    let mut relation_count = 0_usize;
    let mut u = (2 * root) as i64;
    let mut previous_u = u;
    let mut q_value = 0_i64;
    let mut q_denominator = 1_i64;
    let mut previous_denominator = (n - root * root) as i64;
    let mut a_value = 1_i64;
    let mut previous_a = root as i64;
    let mut sign = 0_u64;

    for _ in 0..iteration_limit {
        let old_a = a_value;
        a_value = (q_value * a_value + previous_a) % n_value;
        previous_a = old_a;
        let old_denominator = q_denominator;
        q_denominator = q_value * (previous_u - u) + previous_denominator;
        previous_denominator = old_denominator;
        previous_u = u;
        if q_denominator <= 0 { return n_value; }
        q_value = 1;
        let mut remainder = u - q_denominator;
        if remainder >= q_denominator { q_value = u / q_denominator; remainder = u % q_denominator; }
        u = (2 * root) as i64 - remainder;
        sign ^= 1;
        if q_denominator == 1 { return n_value; }

        let mut residual = q_denominator as u64;
        let mut exponents = [0_u8; MAX_BASE];
        for j in 0..base_count {
            while residual % u64::from(base[j]) == 0 {
                residual /= u64::from(base[j]);
                exponents[j] += 1;
            }
        }
        if residual != 1 { continue; }
        relation_a[relation_count] = a_value as u64;
        relation_exp[relation_count] = exponents;
        let mut vector = sign;
        for j in 0..base_count { if exponents[j] & 1 != 0 { vector |= 1_u64 << (j + 1); } }
        let mut combination = 1_u64 << relation_count;
        relation_count += 1;
        let mut inserted = false;
        for bit in 0..=base_count {
            if vector & (1_u64 << bit) == 0 { continue; }
            if basis_used[bit] {
                vector ^= basis_vector[bit];
                combination ^= basis_combo[bit];
            } else {
                basis_used[bit] = true;
                basis_vector[bit] = vector;
                basis_combo[bit] = combination;
                inserted = true;
                break;
            }
        }
        if !inserted {
            let factor = dependency_factor(n, combination, relation_count, &relation_a, &relation_exp, &base, base_count);
            if factor > 1 { return factor; }
        }
    }
    n_value
}
