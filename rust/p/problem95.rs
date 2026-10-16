const MARK: u32 = 0x8000_0000;
const MASK: u32 = 0x7fff_ffff;
#[no_mangle]
pub extern "C" fn problem95(limit: i64) -> i64 {
    if !(1..=1_000_000).contains(&limit) { return -1; }
    let n = limit as usize;
    let mut sums = vec![0u32; n + 1];
    for divisor in 1..=n / 2 { for multiple in (2 * divisor..=n).step_by(divisor) { sums[multiple] += divisor as u32; } }
    let mut best_length = 0usize;
    let mut answer = 0i64;
    for start in 2..=n {
        let mut current = sums[start];
        let mut length = 1usize;
        sums[start] |= MARK;
        while current > 1 && current as usize <= n && sums[current as usize] & MARK == 0 {
            sums[current as usize] |= MARK;
            current = sums[current as usize] & MASK;
            length += 1;
        }
        if current as usize == start && length > best_length { best_length = length; answer = start as i64; }
        current = start as u32;
        for _ in 0..length { let next = sums[current as usize] & MASK; sums[current as usize] = next; current = next; }
    }
    answer
}
