/// Decide whether a signed integer subset reaches the requested sum.
#[no_mangle]
pub extern "C" fn subset_sum_exists(input: *const i64, length: usize) -> i64 {
    if length == 0 || length > 25 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let target = input[0];
    if !(-6144..=6144).contains(&target) || input[1..].iter().any(|&x| !(-256..=256).contains(&x)) {
        return -1;
    }
    let mut reachable = [false; 12289];
    reachable[6144] = true;
    let (mut low, mut high) = (0i64, 0i64);
    for &value in &input[1..] {
        if value > 0 {
            for sum in (low..=high).rev() {
                if reachable[(sum + 6144) as usize] {
                    reachable[(sum + value + 6144) as usize] = true;
                }
            }
            high += value;
        } else if value < 0 {
            for sum in low..=high {
                if reachable[(sum + 6144) as usize] {
                    reachable[(sum + value + 6144) as usize] = true;
                }
            }
            low += value;
        }
    }
    i64::from(reachable[(target + 6144) as usize])
}
