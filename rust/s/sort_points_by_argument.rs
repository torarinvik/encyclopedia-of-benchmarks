use std::slice;

const MAX_N: usize = 64;
const INPUT_MAX: usize = 129;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }

fn half(point: Point) -> i32 {
    if point.y < 0 { 0 }
    else if point.y == 0 && point.x >= 0 { 1 }
    else { 2 }
}
fn argument_less(a: Point, b: Point) -> bool {
    let (ha, hb) = (half(a), half(b));
    if ha != hb { return ha < hb; }
    let cross = a.x * b.y - a.y * b.x;
    if cross != 0 { return cross > 0; }
    let (ra, rb) = (a.x * a.x + a.y * a.y, b.x * b.x + b.y * b.y);
    if ra != rb { return ra < rb; }
    if a.x != b.x { return a.x < b.x; }
    a.y < b.y
}
unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
}

#[no_mangle]
pub unsafe extern "C" fn sort_points_by_argument(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > INPUT_MAX { return -1; }
    let words = slice::from_raw_parts(input, length);
    let nr = words[0];
    if nr < 1 || nr > MAX_N as i64 || length != 1 + 2 * nr as usize { return -1; }
    let n = nr as usize;
    let mut points = [Point::default(); MAX_N];
    for i in 0..n {
        let (x, y) = (words[1 + 2 * i], words[2 + 2 * i]);
        if !(-1_000_000_000..=1_000_000_000).contains(&x) || !(-1_000_000_000..=1_000_000_000).contains(&y) { return -1; }
        points[i] = Point { x, y };
    }
    let required = 16 * n;
    if output.is_null() || capacity < required { return -2; }
    for i in 1..n {
        let item = points[i];
        let mut j = i;
        while j > 0 && argument_less(item, points[j - 1]) { points[j] = points[j - 1]; j -= 1; }
        points[j] = item;
    }
    for i in 0..n {
        store_le(output, 16 * i, points[i].x);
        store_le(output, 16 * i + 8, points[i].y);
    }
    required as i64
}
