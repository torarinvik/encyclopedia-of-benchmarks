const MAX_LENGTH: i64 = 50;

#[no_mangle]
pub extern "C" fn problem114(length: i64) -> i64 {
    if !(0..=MAX_LENGTH).contains(&length) { return -1; }
    let mut ways = [1i64; 51];
    for row_length in 3..=length {
        for block_length in 3..=row_length {
            for block_start in 0..(row_length - block_length) {
                ways[row_length as usize] += ways[(row_length - block_start - block_length - 1) as usize];
            }
            ways[row_length as usize] += 1;
        }
    }
    ways[length as usize]
}
