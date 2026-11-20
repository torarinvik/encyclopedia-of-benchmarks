const MAX_N: usize = 64;
const MAX_GROUPS: usize = 8;
const MAX_INPUT: usize = 66;
const STACK_CAPACITY: usize = 136;
const INF: i64 = i64::MAX / 4;

#[derive(Clone, Copy, Default)]
struct Task { left: usize, right: usize, low: usize, high: usize }

fn compute_row(previous: &[i64; MAX_N + 1], current: &mut [i64; MAX_N + 1],
               prefix: &[i64; MAX_N + 1], n: usize, group: usize) {
    let mut stack = [Task::default(); STACK_CAPACITY];
    let mut top = 1;
    stack[0] = Task { left: group, right: n, low: group - 1, high: n - 1 };
    while top != 0 {
        top -= 1;
        let task = stack[top];
        if task.left > task.right { continue; }
        let middle = task.left + (task.right - task.left) / 2;
        let upper = task.high.min(middle - 1);
        let mut best = INF;
        let mut best_split = task.low;
        for split in task.low..=upper {
            if previous[split] == INF { continue; }
            let segment = prefix[middle] - prefix[split];
            let candidate = previous[split] + segment * segment;
            if candidate < best { best = candidate; best_split = split; }
        }
        current[middle] = best;
        if middle < task.right {
            stack[top] = Task { left: middle + 1, right: task.right, low: best_split, high: task.high };
            top += 1;
        }
        if task.left < middle {
            stack[top] = Task { left: task.left, right: middle - 1, low: task.low, high: best_split };
            top += 1;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn divide_conquer_dp_partition(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let n_value = input[0];
    let groups_value = input[1];
    if n_value < 1 || n_value > MAX_N as i64 || groups_value < 1 ||
        groups_value > MAX_GROUPS as i64 || groups_value > n_value || length != n_value as usize + 2 { return -1; }
    let n = n_value as usize;
    let groups = groups_value as usize;
    let mut prefix = [0_i64; MAX_N + 1];
    let mut first = [INF; MAX_N + 1];
    let mut second = [INF; MAX_N + 1];
    for i in 0..n {
        let value = input[i + 2];
        if !(0..=1000).contains(&value) { return -1; }
        prefix[i + 1] = prefix[i] + value;
    }
    first[0] = 0;
    let mut previous = &mut first;
    let mut current = &mut second;
    for group in 1..=groups {
        current.fill(INF);
        compute_row(previous, current, &prefix, n, group);
        std::mem::swap(&mut previous, &mut current);
    }
    previous[n]
}
