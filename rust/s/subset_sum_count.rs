/// Count indexed signed subsets that reach the requested sum.
#[no_mangle]
pub extern "C" fn subset_sum_count(input: *const i64, length: usize) -> i64 {
    if length == 0 || length > 25 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let target = input[0];
    if !(-6144..=6144).contains(&target) || input[1..].iter().any(|&x| !(-256..=256).contains(&x)) {
        return -1;
    }
    let mut ways = [0i64; 12289];
    ways[6144] = 1;
    let (mut low, mut high) = (0i64, 0i64);
    for &value in &input[1..] {
        if value > 0 {
            for sum in (low..=high).rev() {
                ways[(sum + value + 6144) as usize] += ways[(sum + 6144) as usize];
            }
            high += value;
        } else if value < 0 {
            for sum in low..=high {
                ways[(sum + value + 6144) as usize] += ways[(sum + 6144) as usize];
            }
            low += value;
        } else {
            for sum in low..=high { ways[(sum + 6144) as usize] *= 2; }
        }
    }
    ways[(target + 6144) as usize]
}
