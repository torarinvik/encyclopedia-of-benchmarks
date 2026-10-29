const MAX_POINTS: usize = 32;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_POINTS;
const COORDINATE_LIMIT: i64 = 1_000_000;

#[no_mangle]
pub extern "C" fn manhattan_mst(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let count_value = values[0];
    if !(1..=MAX_POINTS as i64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != 1 + 2 * count {
        return -1;
    }

    let mut x = [0_i64; MAX_POINTS];
    let mut y = [0_i64; MAX_POINTS];
    for point in 0..count {
        x[point] = values[1 + 2 * point];
        y[point] = values[2 + 2 * point];
        if !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(&x[point])
            || !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(&y[point])
        {
            return -1;
        }
    }

    let mut in_tree = [false; MAX_POINTS];
    let mut has_best = [false; MAX_POINTS];
    let mut best = [0_i64; MAX_POINTS];
    has_best[0] = true;
    let mut total = 0_i64;
    for _ in 0..count {
        let mut selected = count;
        for point in 0..count {
            if !in_tree[point]
                && has_best[point]
                && (selected == count || best[point] < best[selected])
            {
                selected = point;
            }
        }
        if selected == count {
            return -1;
        }
        in_tree[selected] = true;
        total += best[selected];
        for point in 0..count {
            if in_tree[point] {
                continue;
            }
            let distance = (x[selected] - x[point]).abs() + (y[selected] - y[point]).abs();
            if !has_best[point] || distance < best[point] {
                has_best[point] = true;
                best[point] = distance;
            }
        }
    }
    total
}
