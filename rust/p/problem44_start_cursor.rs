const MAX_START: i64 = 2166;
const MAX_HIGH_INDEX: i64 = 2167;

fn pentagonal(index: i64) -> i64 {
    index * (3 * index - 1) / 2
}

fn integer_sqrt(value: i64) -> i64 {
    let mut low = 0i64;
    let mut high = 20_000i64;
    while high - low > 1 {
        let middle = (low + high) / 2;
        if middle * middle <= value { low = middle; }
        else { high = middle; }
    }
    low
}

fn is_pentagonal(value: i64) -> bool {
    let discriminant = 24 * value + 1;
    let root = integer_sqrt(discriminant);
    root * root == discriminant && (root + 1) % 6 == 0
}

#[no_mangle]
pub extern "C" fn problem44_start_cursor(start: i64) -> i64 {
    if !(1..=MAX_START).contains(&start) { return -1; }
    let mut high = start + 1;
    while high <= MAX_HIGH_INDEX {
        let high_value = pentagonal(high);
        let mut low = high - 1;
        while low > 0 {
            let low_value = pentagonal(low);
            let difference = high_value - low_value;
            let sum = high_value + low_value;
            if is_pentagonal(difference) && is_pentagonal(sum) { return difference; }
            low -= 1;
        }
        high += 1;
    }
    -1
}
