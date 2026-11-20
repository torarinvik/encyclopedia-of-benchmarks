const MAX_PRIME: i64 = 1_000_000;
const PACK_BASE: i64 = 1024;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor = if divisor == 2 { 3 } else { divisor + 2 };
    }
    true
}

fn isqrt(value: i64) -> i64 {
    let mut low = 0_i64;
    let mut high = 1001_i64;
    while low + 1 < high {
        let middle = (low + high) / 2;
        if middle * middle <= value { low = middle; }
        else { high = middle; }
    }
    low
}

fn implementation(prime: i64, root: i64) -> i64 {
    if prime < 3 || prime > MAX_PRIME || (prime & 1) == 0 || root < 1 || root > prime / 2 { return -1; }
    if !is_prime(prime) || (root * root + 2) % prime != 0 { return -1; }

    let mut previous = prime;
    let mut current = root;
    let limit = isqrt(prime);
    while current > limit {
        let remainder = previous % current;
        previous = current;
        current = remainder;
    }
    let x = current;
    let numerator = prime - x * x;
    if numerator <= 0 || numerator % 2 != 0 { return -1; }
    let y_squared = numerator / 2;
    let y = isqrt(y_squared);
    if y <= 0 || y * y != y_squared || x * x + 2 * y * y != prime { return -1; }
    x * PACK_BASE + y
}

#[no_mangle]
pub unsafe extern "C" fn cornacchia_x2_plus_2y2(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    implementation(*input, *input.add(1))
}
