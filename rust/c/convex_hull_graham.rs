const MAX_POINTS: usize = 64;

fn cross(a: usize, b: usize, c: usize, values: &[i64]) -> i64 {
    let (ax, ay) = (values[2 * a], values[2 * a + 1]);
    let (bx, by) = (values[2 * b], values[2 * b + 1]);
    let (cx, cy) = (values[2 * c], values[2 * c + 1]);
    (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}

fn orientation(a: usize, b: usize, c: usize, values: &[i64]) -> i32 {
    let turn = cross(a, b, c, values);
    if turn < 0 { 1 } else if turn > 0 { -1 } else { 0 }
}

unsafe fn write_index(output: *mut u8, position: usize, id: usize) {
    let value = id as u32;
    for byte in 0..4 { *output.add(4 * position + byte) = (value >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn convex_hull_graham(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if length % 2 != 0 || length > 2 * MAX_POINTS || values.is_null() { return -1; }
    let count = length / 2;
    if !(3..=MAX_POINTS).contains(&count) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&coordinate| !(-2000..=2000).contains(&coordinate)) { return -1; }

    let mut order: Vec<usize> = (0..count).collect();
    order.sort_by_key(|&index| values[2 * index]);
    if order.windows(2).any(|pair| values[2 * pair[0]] == values[2 * pair[1]]) { return -1; }
    for index in 1..count - 1 {
        if cross(order[0], order[index], order[count - 1], values) == 0 { return -1; }
    }

    let mut upper = vec![0usize];
    let mut lower = vec![0usize];
    for index in 1..count {
        let turn = orientation(order[0], order[index], order[count - 1], values);
        if index == count - 1 || turn != -1 {
            while upper.len() >= 2 && orientation(order[upper[upper.len() - 2]],
                order[*upper.last().unwrap()], order[index], values) == -1 { upper.pop(); }
            upper.push(index);
        }
        if index == count - 1 || turn != 1 {
            while lower.len() >= 2 && orientation(order[lower[lower.len() - 2]],
                order[*lower.last().unwrap()], order[index], values) == 1 { lower.pop(); }
            lower.push(index);
        }
    }
    let hull_count = upper.len() - 2 + lower.len();
    if output.is_null() || capacity < 4 * hull_count { return -2; }
    let mut written = 0;
    for &position in upper.iter().skip(1).take(upper.len() - 2) {
        write_index(output, written, order[position]);
        written += 1;
    }
    for &position in lower.iter().rev() {
        write_index(output, written, order[position]);
        written += 1;
    }
    hull_count as i64
}
