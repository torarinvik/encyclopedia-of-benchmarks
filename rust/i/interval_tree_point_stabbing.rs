const MAX_N: usize = 16;
const MAX_Q: usize = 8;
const TREE_CAP: usize = 32;
const MAX_OUTPUT: usize = 72;

#[derive(Clone, Copy, Default)]
struct Interval { low: i64, high: i64, id: usize }

fn place_balanced(sorted: &[Interval; MAX_N], tree: &mut [Interval; TREE_CAP],
                  used: &mut [bool; TREE_CAP], first: isize, last: isize, node: usize) {
    if first > last || node >= TREE_CAP { return; }
    let middle = (first + (last - first) / 2) as usize;
    tree[node] = sorted[middle];
    used[node] = true;
    place_balanced(sorted, tree, used, first, middle as isize - 1, 2 * node + 1);
    place_balanced(sorted, tree, used, middle as isize + 1, last, 2 * node + 2);
}

fn write_i64_le(staged: &mut [u8; MAX_OUTPUT], offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    staged[offset..offset + 8].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn interval_tree_point_stabbing(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 43 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n64 = values[0];
    let q64 = values[1];
    if !(0..=MAX_N as i64).contains(&n64) || !(0..=MAX_Q as i64).contains(&q64) { return -1; }
    let n = n64 as usize;
    let q = q64 as usize;
    if length != 2 + 2 * n + q { return -1; }
    let mut sorted = [Interval::default(); MAX_N];
    let mut at = 2;
    for id in 0..n {
        let low = values[at];
        let high = values[at + 1];
        at += 2;
        if !(-32..=32).contains(&low) || !(-32..=32).contains(&high) || low > high { return -1; }
        sorted[id] = Interval { low, high, id };
    }
    let mut points = [0i64; MAX_Q];
    for point in points.iter_mut().take(q) {
        *point = values[at]; at += 1;
        if !(-32..=32).contains(point) { return -1; }
    }
    for i in 1..n {
        let value = sorted[i];
        let mut j = i;
        while j > 0 {
            let previous = sorted[j - 1];
            if (previous.low, previous.high, previous.id) <= (value.low, value.high, value.id) { break; }
            sorted[j] = previous;
            j -= 1;
        }
        sorted[j] = value;
    }
    let mut tree = [Interval::default(); TREE_CAP];
    let mut used = [false; TREE_CAP];
    let mut maximum = [i64::MIN; TREE_CAP];
    if n > 0 { place_balanced(&sorted, &mut tree, &mut used, 0, n as isize - 1, 0); }
    for node in (0..TREE_CAP).rev() {
        if !used[node] { continue; }
        maximum[node] = tree[node].high;
        let left = 2 * node + 1;
        let right = left + 1;
        if left < TREE_CAP && used[left] { maximum[node] = maximum[node].max(maximum[left]); }
        if right < TREE_CAP && used[right] { maximum[node] = maximum[node].max(maximum[right]); }
    }
    let mut masks = [0i64; MAX_Q];
    for qi in 0..q {
        let mut stack = [0usize; TREE_CAP];
        let mut top = 0;
        if n > 0 { stack[top] = 0; top += 1; }
        while top > 0 {
            top -= 1;
            let node = stack[top];
            if !used[node] || maximum[node] < points[qi] { continue; }
            let left = 2 * node + 1;
            let right = left + 1;
            if left < TREE_CAP && used[left] && maximum[left] >= points[qi] { stack[top] = left; top += 1; }
            if tree[node].low <= points[qi] && points[qi] <= tree[node].high { masks[qi] |= 1i64 << tree[node].id; }
            if tree[node].low <= points[qi] && right < TREE_CAP && used[right] && maximum[right] >= points[qi] { stack[top] = right; top += 1; }
        }
    }
    let bytes = (q + 1) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    write_i64_le(&mut staged, 0, q as i64);
    for i in 0..q { write_i64_le(&mut staged, (i + 1) * 8, masks[i]); }
    for i in 0..bytes { unsafe { *output.add(i) = staged[i]; } }
    bytes as i64
}
