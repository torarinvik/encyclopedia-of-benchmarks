const MAX_LIMIT: i64 = 100_000_000;
const HASH_CAPACITY: usize = 32768;
const HASH_MASK: usize = HASH_CAPACITY - 1;

fn is_palindrome(value: i64) -> bool {
    if value % 10 == 0 { return false; }
    let original = value;
    let mut remaining = value;
    let mut reversed = 0i64;
    while remaining > 0 {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
    }
    original == reversed
}

fn insert_unique(seen: &mut [i64; HASH_CAPACITY], value: i64) -> bool {
    let mut slot = (((value as u64 * 2_654_435_761u64) >> 17) as usize) & HASH_MASK;
    while seen[slot] != 0 && seen[slot] != value { slot = (slot + 1) & HASH_MASK; }
    if seen[slot] == value { return false; }
    seen[slot] = value;
    true
}

#[no_mangle]
pub extern "C" fn problem125(limit: i64) -> i64 {
    if !(0..=MAX_LIMIT).contains(&limit) { return -1; }
    let mut seen = [0i64; HASH_CAPACITY];
    let mut total = 0i64;
    let mut first = 1i64;
    loop {
        let mut last = first + 1;
        let mut sum = first * first + last * last;
        if sum >= limit { break; }
        while sum < limit {
            if is_palindrome(sum) && insert_unique(&mut seen, sum) { total += sum; }
            last += 1;
            sum += last * last;
        }
        first += 1;
    }
    total
}
