#[no_mangle]
pub extern "C" fn problem115(min_block_length: i64) -> i64 {
    if !(1..=100).contains(&min_block_length) { return -1; }
    let mut ways = [0_i64; 1024];
    let min_block_length = min_block_length as usize;
    for i in 0..min_block_length { ways[i] = 1; }
    for n in min_block_length..1024 {
        ways[n] = 1;
        for block_length in min_block_length..=n {
            for block_start in 0..(n - block_length) {
                ways[n] += ways[n - block_start - block_length - 1];
            }
            ways[n] += 1;
        }
        if ways[n] > 1_000_000 { return n as i64; }
    }
    -1
}
