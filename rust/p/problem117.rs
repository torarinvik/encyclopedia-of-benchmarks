#[no_mangle]
pub extern "C" fn problem117(length: i64) -> i64 {
    if !(0..=67).contains(&length) { return -1; }
    let n = length as usize;
    let mut ways = [0i64; 68];
    ways[0] = 1;
    for row in 1..=n {
        ways[row] = ways[row - 1];
        if row >= 2 { ways[row] += ways[row - 2]; }
        if row >= 3 { ways[row] += ways[row - 3]; }
        if row >= 4 { ways[row] += ways[row - 4]; }
    }
    ways[n]
}
