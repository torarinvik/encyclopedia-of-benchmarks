const MAX_POINTS: usize = 8;
const MAX_DISTANCE: i64 = 1_000_000;
const JAVA_INT_MAX: i64 = 2_147_483_647;
const MAX_INPUT_LENGTH: usize = 2 + MAX_POINTS * MAX_POINTS;

#[no_mangle]
pub extern "C" fn kcenters(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let point_count = values[0];
    let center_count = values[1];
    if !(1..=MAX_POINTS as i64).contains(&point_count)
        || !(1..=point_count).contains(&center_count)
        || length != 2 + point_count as usize * point_count as usize { return -1; }
    let point_count = point_count as usize;
    let matrix = &values[2..];
    for row in 0..point_count {
        for column in 0..point_count {
            let distance = matrix[row * point_count + column];
            if !(0..=MAX_DISTANCE).contains(&distance) || (row == column && distance != 0)
                || distance != matrix[column * point_count + row] { return -1; }
        }
    }

    let mut selected = [false; MAX_POINTS];
    let mut max_distance = [JAVA_INT_MAX; MAX_POINTS];
    selected[0] = true;
    for point in 1..point_count { max_distance[point] = max_distance[point].min(matrix[point]); }
    for _ in 1..center_count as usize {
        let mut farthest: Option<usize> = None;
        for point in 0..point_count {
            if !selected[point]
                && farthest.map_or(true, |current| max_distance[point] > max_distance[current])
            {
                farthest = Some(point);
            }
        }
        let farthest = farthest.unwrap();
        selected[farthest] = true;
        for point in 0..point_count {
            max_distance[point] = max_distance[point].min(matrix[farthest * point_count + point]);
        }
    }
    max_distance[..point_count].iter().copied().max().unwrap_or(0)
}
