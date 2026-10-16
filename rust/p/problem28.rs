/// Bounded port of TheAlgorithms/Python Project Euler 28 layer summation.
#[no_mangle]
pub extern "C" fn problem28(size: i64) -> i64 {
    if !(0..=100_000).contains(&size) {
        return -1;
    }
    let mut total = 1i64;
    let layer_count = (size + 1) / 2;
    for layer in 1..layer_count {
        let odd_corner = 2 * layer + 1;
        let even_corner = 2 * layer;
        total += 4 * odd_corner * odd_corner - 6 * even_corner;
    }
    total
}
