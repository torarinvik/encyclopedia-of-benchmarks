const MAX_LIMIT: i64 = 10_000;

fn integer_sqrt(value: i64) -> i64 {
    let mut low = 0i64;
    let mut high = value + 1;
    while high - low > 1 {
        let middle = low + (high - low) / 2;
        if middle <= value / middle { low = middle; }
        else { high = middle; }
    }
    low
}

fn period_length(value: i64, root: i64) -> i64 {
    let mut numerator = 0i64;
    let mut denominator = 1i64;
    let mut coefficient = root;
    let mut period = 0i64;
    loop {
        numerator = denominator * coefficient - numerator;
        denominator = (value - numerator * numerator) / denominator;
        coefficient = (root + numerator) / denominator;
        period += 1;
        if coefficient == 2 * root { break; }
    }
    period
}

#[no_mangle]
pub extern "C" fn problem64(inclusive_limit: i64) -> i64 {
    if inclusive_limit < 0 || inclusive_limit > MAX_LIMIT { return -1; }
    let mut count = 0i64;
    for value in 2..=inclusive_limit {
        let root = integer_sqrt(value);
        if root * root != value && period_length(value, root) % 2 == 1 {
            count += 1;
        }
    }
    count
}
