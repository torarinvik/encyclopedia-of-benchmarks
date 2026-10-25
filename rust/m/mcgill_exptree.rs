const MAX_LEAVES: usize = 4;

#[derive(Clone, Copy, Default)]
struct Combination { left: i64, right: i64, operation: i32 }
struct Search {
    count: usize,
    depth_limit: usize,
    goal: i64,
    best: i64,
    stopped: bool,
    work: [i64; 2 * MAX_LEAVES],
    current: [Combination; MAX_LEAVES],
    saved: [Combination; MAX_LEAVES],
}

fn distance_from(a: i64, b: i64) -> i64 { (a - b).abs() }
fn apply(a: i64, b: i64, op: i32) -> i64 {
    match op { 1 => a + b, 2 => a - b, 3 => a * b, _ => a / b }
}
fn search(s: &mut Search, depth: usize, used: u32) {
    if s.stopped { return; }
    if depth == s.depth_limit {
        let candidate = s.work[s.count + depth - 1];
        if distance_from(candidate, s.goal) < distance_from(s.best, s.goal) {
            s.best = candidate;
            for i in 0..depth { s.saved[i] = s.current[i]; }
            if s.best == s.goal { s.stopped = true; }
        }
        return;
    }
    for op in 1..=4 {
        if s.stopped { break; }
        for first in 0..(s.count + depth) {
            if s.stopped { break; }
            if used & (1u32 << first) != 0 { continue; }
            for second in 0..first {
                if s.stopped { break; }
                if used & (1u32 << second) != 0 { continue; }
                let (mut left, mut right) = (s.work[first], s.work[second]);
                if (op == 3 || op == 4) && (left == 1 || right == 1) { continue; }
                if left == 0 || right == 0 { continue; }
                if op == 4 && left % right != 0 { continue; }
                if (op == 2 || op == 4) && left < right { std::mem::swap(&mut left, &mut right); }
                s.current[depth] = Combination { left, right, operation: op };
                s.work[s.count + depth] = apply(left, right, op);
                search(s, depth + 1, used | (1u32 << first) | (1u32 << second));
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn mcgill_exptree(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=6).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (goal, raw_count) = (values[0], values[1]);
    if !(1..=1_000_000_000).contains(&goal) || !(1..=MAX_LEAVES as i64).contains(&raw_count) ||
        length != raw_count as usize + 2 { return -1; }
    let mut s = Search {
        count: raw_count as usize, depth_limit: 0, goal, best: 0, stopped: false,
        work: [0; 2 * MAX_LEAVES], current: [Combination::default(); MAX_LEAVES],
        saved: [Combination::default(); MAX_LEAVES],
    };
    for i in 0..s.count {
        let value = values[2 + i];
        if !(1..=100).contains(&value) { return -1; }
        s.work[i] = value;
    }
    for i in 0..s.count {
        if distance_from(s.work[i], s.goal) < distance_from(s.best, s.goal) { s.best = s.work[i]; }
    }
    if s.best == s.goal { return s.best; }
    for depth_limit in 1..s.count {
        s.depth_limit = depth_limit;
        search(&mut s, 0, 0);
        if s.stopped { break; }
    }
    s.best
}
