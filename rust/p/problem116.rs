/// Count single-color block replacements for lengths two, three, and four.
const MAX_LENGTH: i64 = 91;

#[no_mangle]
pub extern "C" fn problem116(length: i64) -> i64 {
    if length > MAX_LENGTH { return -1; }
    if length < 0 { return -1; }
    let mut ways = [0i64; 276];
    for row_length in 0..=length {
        for tile_length in 2..5 {
            let color = tile_length - 2;
            let mut tile_start = 0;
            while tile_start < row_length - tile_length + 1 {
                let suffix = row_length - tile_start - tile_length;
                let index = (row_length * 3 + color) as usize;
                let suffix_index = (suffix * 3 + color) as usize;
                ways[index] += ways[suffix_index] + 1;
                tile_start += 1;
            }
        }
    }
    ways[(length * 3) as usize] + ways[(length * 3 + 1) as usize] + ways[(length * 3 + 2) as usize]
}
