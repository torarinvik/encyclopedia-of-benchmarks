/// Compute Fibonacci numbers by portable 64-bit fast doubling.
#[no_mangle]
pub extern "C" fn fibonacci_fast(input: i64) -> i64 {
    if !(0..=92).contains(&input) { return -1; }
    let n = input as u64;
    let mut bit = 1_u64;
    while bit <= n / 2 { bit <<= 1; }
    let (mut current, mut next) = (0_u64, 1_u64);
    while bit != 0 {
        let even = current * (2 * next - current);
        let odd = current * current + next * next;
        if n & bit != 0 {
            current = odd;
            next = even + odd;
        } else {
            current = even;
            next = odd;
        }
        bit >>= 1;
    }
    current as i64
}
