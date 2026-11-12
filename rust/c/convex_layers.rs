use std::slice;

const MAX_POINTS: usize = 64;
const COORD_LIMIT: i64 = 1_000_000;

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
struct Point { x: i64, y: i64 }

fn cross(a: Point, b: Point, c: Point) -> i64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

fn on_segment(point: Point, a: Point, b: Point) -> bool {
    cross(a, b, point) == 0 &&
        a.x.min(b.x) <= point.x && point.x <= a.x.max(b.x) &&
        a.y.min(b.y) <= point.y && point.y <= a.y.max(b.y)
}

fn hull(mut points: Vec<Point>) -> Vec<Point> {
    points.sort_unstable();
    if points.len() <= 2 { return points; }
    let mut result = Vec::with_capacity(2 * points.len());
    for &point in &points {
        while result.len() >= 2 && cross(result[result.len() - 2], *result.last().unwrap(), point) <= 0 {
            result.pop();
        }
        result.push(point);
    }
    let lower = result.len();
    for index in (0..points.len() - 1).rev() {
        let point = points[index];
        while result.len() > lower && cross(result[result.len() - 2], *result.last().unwrap(), point) <= 0 {
            result.pop();
        }
        result.push(point);
    }
    result.pop();
    result
}

#[no_mangle]
pub unsafe extern "C" fn convex_layers(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=1 + 2 * MAX_POINTS).contains(&length) { return -1; }
    let values = slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(0..=MAX_POINTS as i64).contains(&count_value) || length != 1 + 2 * count_value as usize {
        return -1;
    }
    let mut points = Vec::with_capacity(count_value as usize);
    for pair in values[1..].chunks_exact(2) {
        let point = Point { x: pair[0], y: pair[1] };
        if point.x < -COORD_LIMIT || point.x > COORD_LIMIT ||
            point.y < -COORD_LIMIT || point.y > COORD_LIMIT { return -1; }
        if !points.contains(&point) { points.push(point); }
    }

    let mut layers = 0;
    while !points.is_empty() {
        let old_count = points.len();
        let boundary = hull(points.clone());
        let mut remaining = Vec::with_capacity(points.len());
        for point in points {
            let on_boundary = boundary.len() <= 2 || (0..boundary.len()).any(|edge|
                on_segment(point, boundary[edge], boundary[(edge + 1) % boundary.len()]));
            if !on_boundary { remaining.push(point); }
        }
        if remaining.len() == old_count { return -1; }
        points = remaining;
        layers += 1;
    }
    layers
}
