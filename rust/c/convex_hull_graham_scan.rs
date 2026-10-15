use std::cmp::Ordering;

const MAX_POINTS: usize = 1024;
#[derive(Clone, Copy)]
struct Point { x: i64, y: i64, id: usize }

fn cross(a: Point, b: Point, c: Point) -> i64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}
fn radius_squared(pivot: Point, point: Point) -> i64 {
    let dx = point.x - pivot.x;
    let dy = point.y - pivot.y;
    dx * dx + dy * dy
}

unsafe fn write_hull(points: &[Point], hull: &[usize], output: *mut u8, capacity: usize) -> i64 {
    if output.is_null() || capacity < 4 * hull.len() { return -2; }
    for (position, &point_index) in hull.iter().enumerate() {
        let id = points[point_index].id as u32;
        for byte in 0..4 { *output.add(4 * position + byte) = (id >> (8 * byte)) as u8; }
    }
    hull.len() as i64
}

#[no_mangle]
pub unsafe extern "C" fn convex_hull_graham_scan(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values.is_null()) { return -1; }
    let count = length / 2;
    let mut input = Vec::with_capacity(count);
    for index in 0..count {
        let x = *values.add(2 * index);
        let y = *values.add(2 * index + 1);
        if !(-1_000_000_000..=1_000_000_000).contains(&x) ||
            !(-1_000_000_000..=1_000_000_000).contains(&y) { return -1; }
        input.push(Point { x, y, id: index });
    }
    if input.is_empty() { return 0; }
    input.sort_by_key(|point| (point.x, point.y, point.id));
    let mut points: Vec<Point> = Vec::with_capacity(input.len());
    for point in input {
        if points.last().map_or(true, |last| last.x != point.x || last.y != point.y) { points.push(point); }
    }
    if points.len() == 1 { return write_hull(&points, &[0], output, output_capacity); }

    let mut pivot = 0;
    for index in 1..points.len() {
        if (points[index].y, points[index].x) < (points[pivot].y, points[pivot].x) { pivot = index; }
    }
    let mut order: Vec<usize> = (0..points.len()).collect();
    order.sort_by(|&a, &b| {
        let turn = cross(points[pivot], points[a], points[b]);
        if turn != 0 { return if turn > 0 { Ordering::Less } else { Ordering::Greater }; }
        radius_squared(points[pivot], points[a]).cmp(&radius_squared(points[pivot], points[b]))
            .then(points[a].id.cmp(&points[b].id))
    });
    let all_collinear = (2..order.len()).all(|index|
        cross(points[pivot], points[order[1]], points[order[index]]) == 0);
    if !all_collinear {
        let mut ray_begin = order.len() - 1;
        while ray_begin > 1 && cross(points[pivot], points[order[ray_begin - 1]],
                                     points[order[order.len() - 1]]) == 0 {
            ray_begin -= 1;
        }
        order[ray_begin..].reverse();
    }
    let mut hull = Vec::with_capacity(points.len());
    for point in order {
        while hull.len() >= 2 && cross(points[hull[hull.len() - 2]], points[*hull.last().unwrap()], points[point]) < 0 {
            hull.pop();
        }
        hull.push(point);
    }
    write_hull(&points, &hull, output, output_capacity)
}
