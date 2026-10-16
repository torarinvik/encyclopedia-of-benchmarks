#[no_mangle]
pub extern "C" fn problem109(limit: i64) -> i64 {
    let mut values = [0i64; 63];
    let mut doubles = [0i64; 21];
    let (mut value_count, mut double_count) = (0usize, 0usize);
    for score in 1..=20 { values[value_count] = score; value_count += 1; }
    values[value_count] = 25; value_count += 1;
    for score in 1..=20 { doubles[double_count] = 2 * score; values[value_count] = 2 * score; double_count += 1; value_count += 1; }
    doubles[double_count] = 50; values[value_count] = 50; double_count += 1; value_count += 1;
    for score in 1..=20 { values[value_count] = 3 * score; value_count += 1; }
    values[value_count] = 0; value_count += 1;
    let mut count = 0i64;
    for d in 0..double_count { for first in 0..value_count { for second in first..value_count {
        count += i64::from(doubles[d] + values[first] + values[second] < limit);
    } } }
    count
}
