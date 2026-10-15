/// Count set bits in the bounded unsigned 53-bit domain, byte by byte.
const MAX_UINT53: i64 = 9_007_199_254_740_991;

fn count_byte_ones(mut byte: i64) -> i64 {
    let mut ones = 0;
    while byte > 0 {
        let bit = byte % 2;
        ones += bit;
        byte = (byte - bit) / 2;
    }
    ones
}

#[no_mangle]
pub extern "C" fn uint53_ones_count(n: i64) -> i64 {
    if !(0..=MAX_UINT53).contains(&n) {
        return -1;
    }

    let mut current = n;
    let mut ones = 0;
    while current != 0 {
        let byte = current % 256;
        ones += count_byte_ones(byte);
        current = (current - byte) / 256;
    }
    ones
}
