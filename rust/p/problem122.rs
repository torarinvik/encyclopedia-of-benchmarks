fn solve(chain: &mut [i64; 32], length: usize, goal: i64, depth: usize) -> bool {
    let last = chain[length - 1];
    for index in 0..length {
        let next = chain[index] + last;
        if next == goal { return true; }
        if next > goal { break; }
        if length < depth { chain[length] = next; if solve(chain, length + 1, goal, depth) { return true; } }
    }
    false
}
#[no_mangle]
pub extern "C" fn problem122(maximum: i64) -> i64 {
    if !(0..=200).contains(&maximum) { return -1; }
    let mut total = 0i64;
    for goal in 2..=maximum {
        let mut chain = [0i64; 32]; chain[0] = 1;
        let mut depth = 0usize;
        loop { depth += 1; chain[0] = 1; if solve(&mut chain, 1, goal, depth) { break; } }
        total += depth as i64;
    }
    total
}
