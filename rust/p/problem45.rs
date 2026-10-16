const MAX_INDEX: i64 = 27_693;

fn integer_sqrt(value: i64) -> i64 {
    let mut low = 0i64;
    let mut high = 200_000i64;
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
pub extern "C" fn problem45(start: i64) -> i64 {
    if !(0..=MAX_INDEX).contains(&start) { return -1; }
    let mut index = start;
    while index <= MAX_INDEX {
        let value = index * (2 * index - 1);
        if is_pentagonal(value) { return value; }
        index += 1;
    }
    -1
}
