/// Return the exact Bell number for indices that fit in signed 64-bit output.
#[no_mangle]
pub extern "C" fn bell_numbers(n: i64) -> i64 {
    if !(0..=25).contains(&n) {
        return -1;
    }
    if n == 0 {
        return 1;
    }

    let mut row = [0i64; 26];
    row[0] = 1;
    for current in 1..n as usize {
        let previous_first = row[0];
        let previous_last = row[current - 1];
        row[0] = previous_last;
        let mut previous_old = previous_first;
        for column in 1..=current {
            let old_value = if column < current { row[column] } else { 0 };
            row[column] = row[column - 1] + previous_old;
            previous_old = old_value;
        }
    }
    row[n as usize - 1]
}
