#[no_mangle]
pub extern "C" fn make_change_sequence(amount: i64) -> i64 {
    if !(0..=128).contains(&amount) {
        return -1;
    }
    let mut values = [0i64; 129];
    values[..17].copy_from_slice(&[1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 11, 12, 15, 16, 19, 22, 25]);
    for n in 17..=amount as usize {
        values[n] = values[n - 2] + values[n - 5] - values[n - 7]
                  + values[n - 10] - values[n - 12] - values[n - 15]
                  + values[n - 17] + 1;
    }
    values[amount as usize]
}
