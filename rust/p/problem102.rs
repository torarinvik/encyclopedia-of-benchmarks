/// Count triangles whose strict interior contains the origin.
const MAX_VALUES: usize = 6_000;
const MIN_COORD: i64 = -1_000;
const MAX_COORD: i64 = 1_000;

fn origin_inside(x1: i64, y1: i64, x2: i64, y2: i64, x3: i64, y3: i64) -> i64 {
    let abx = x2 - x1;
    let aby = y2 - y1;
    let acx = x3 - x1;
    let acy = y3 - y1;
    let mut denominator = acx * aby - acy * abx;
    let mut numerator_a = -(x1 * aby - y1 * abx);
    let mut numerator_b = x1 * acy - y1 * acx;
    if denominator == 0 { return -1; }
    if denominator < 0 {
        denominator = -denominator;
        numerator_a = -numerator_a;
        numerator_b = -numerator_b;
    }
    if numerator_a > 0 && numerator_b > 0 && numerator_a + numerator_b < denominator { 1 } else { 0 }
}

#[no_mangle]
pub unsafe extern "C" fn problem102(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_VALUES || length % 6 != 0 { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if value < MIN_COORD || value > MAX_COORD { return -1; }
    }
    let mut count = 0i64;
    let mut offset = 0usize;
    while offset < length {
        let inside = origin_inside(
            *input.add(offset), *input.add(offset + 1), *input.add(offset + 2),
            *input.add(offset + 3), *input.add(offset + 4), *input.add(offset + 5),
        );
        if inside < 0 { return -1; }
        count += inside;
        offset += 6;
    }
    count
}
