const MAX_POINTS: usize = 1024;
#[derive(Clone, Copy)]
struct Point { x: i64, y: i64, id: usize }

fn cross(a: Point, b: Point, c: Point) -> i64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn quick_hull(points: &[Point], left: usize, right: usize, on_hull: &mut [bool]) {
    let mut farthest = None;
    let mut greatest_area = 0_i64;
    for (index, &point) in points.iter().enumerate() {
        let area = cross(points[left], points[right], point);
        if area > greatest_area { greatest_area = area; farthest = Some(index); }
    }
    let Some(farthest) = farthest else { return; };
    on_hull[farthest] = true;
    quick_hull(points, left, farthest, on_hull);
    quick_hull(points, farthest, right, on_hull);
}

unsafe fn write_hull(points: &[Point], on_hull: &[bool], output: *mut u8, capacity: usize) -> i64 {
    let count = on_hull.iter().filter(|&&included| included).count();
    if output.is_null() || capacity < 4 * count { return -2; }
    let mut position = 0;
    for (index, point) in points.iter().enumerate() {
        if !on_hull[index] { continue; }
        let id = point.id as u32;
        for byte in 0..4 { *output.add(4 * position + byte) = (id >> (8 * byte)) as u8; }
        position += 1;
    }
    count as i64
}

#[no_mangle]
pub unsafe extern "C" fn convex_hull_quickhull(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values.is_null()) { return -1; }
    let count = length / 2;
    let mut points = Vec::with_capacity(count);
    for index in 0..count {
        let x = *values.add(2 * index);
        let y = *values.add(2 * index + 1);
        if !(-1_000_000_000..=1_000_000_000).contains(&x) ||
            !(-1_000_000_000..=1_000_000_000).contains(&y) { return -1; }
        points.push(Point { x, y, id: index });
    }
    if points.is_empty() { return 0; }
    points.sort_by_key(|point| (point.x, point.y, point.id));
    points.dedup_by(|right, left| right.x == left.x && right.y == left.y);
    let mut on_hull = vec![false; points.len()];
    if points.len() == 1 { on_hull[0] = true; }
    else {
        on_hull[0] = true;
        on_hull[points.len() - 1] = true;
        quick_hull(&points, 0, points.len() - 1, &mut on_hull);
        quick_hull(&points, points.len() - 1, 0, &mut on_hull);
    }
    write_hull(&points, &on_hull, output, output_capacity)
}
