#[no_mangle]
pub extern "C" fn newton_square_root(value: i64) -> i64 {
    if value < 0 || value > 4_611_686_018_427_387_903 {
        return -1;
    }
    if value == 0 {
        return 0;
    }

    let bit_length = (value as f64).log2().ceil() as u32;
    let mut root = 1_i64 << (bit_length / 2);
    while !(value >= root * root && value <= root * root + root + root) {
        root += value / root;
        root /= 2;
    }
    root
}
