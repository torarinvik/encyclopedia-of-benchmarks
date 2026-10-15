/// Tabulated Fibonacci for the bounded signed 64-bit benchmark contract.
#[no_mangle]
pub extern "C" fn fibonacci_dp(n: i64) -> i64 {
    if !(0..=46).contains(&n) {
        return -1;
    }

    let mut table = [0i64; 47];
    table[0] = 0;
    table[1] = 1;
    let mut index = 2usize;
    while index <= n as usize {
        table[index] = table[index - 1] + table[index - 2];
        index += 1;
    }
    table[n as usize]
}
