const MAX_POINTS: usize = 1024;
const MAX_COORDINATE: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[derive(Clone, Copy, PartialEq, Eq)]
struct Point { x: i64, y: i64 }

fn cross(origin: Point, a: Point, b: Point) -> i64 {
    (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x)
}

fn distance_squared(a: Point, b: Point) -> u64 {
    let dx = a.x - b.x;
    let dy = a.y - b.y;
    (dx * dx) as u64 + (dy * dy) as u64
}

#[no_mangle]
pub unsafe extern "C" fn rotating_calipers(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 5 || length > 2 * MAX_POINTS + 1 || length % 2 == 0 {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    let count = values[0];
    if count < 2 || count > MAX_POINTS as i64 || length != 1 + 2 * count as usize {
        return INVALID_RESULT;
    }
    let mut points = Vec::with_capacity(count as usize);
    for index in 0..count as usize {
        let point = Point { x: values[1 + 2 * index], y: values[2 + 2 * index] };
        if !(-MAX_COORDINATE..=MAX_COORDINATE).contains(&point.x)
            || !(-MAX_COORDINATE..=MAX_COORDINATE).contains(&point.y) {
            return INVALID_RESULT;
        }
        points.push(point);
    }
    points.sort_unstable_by_key(|p| (p.x, p.y));
    points.dedup();
    if points.len() == 1 { return 0.0; }

    let mut lower: Vec<Point> = Vec::with_capacity(points.len());
    for point in points.iter().copied() {
        while lower.len() >= 2 && cross(lower[lower.len()-2], lower[lower.len()-1], point) <= 0 {
            lower.pop();
        }
        lower.push(point);
    }
    let mut upper: Vec<Point> = Vec::with_capacity(points.len());
    for point in points.iter().rev().copied() {
        while upper.len() >= 2 && cross(upper[upper.len()-2], upper[upper.len()-1], point) <= 0 {
            upper.pop();
        }
        upper.push(point);
    }
    lower.pop();
    upper.pop();
    lower.extend(upper);
    let hull = lower;
    if hull.len() == 2 { return (distance_squared(hull[0], hull[1]) as f64).sqrt(); }

    let size = hull.len();
    let mut antipodal = 1usize;
    let mut advances = 0usize;
    while advances < size && cross(hull[0], hull[1], hull[(antipodal + 1) % size])
        > cross(hull[0], hull[1], hull[antipodal]) {
        antipodal = (antipodal + 1) % size;
        advances += 1;
    }
    let mut maximum_squared = 0u64;
    for current in 0..size {
        let next = (current + 1) % size;
        advances = 0;
        while advances < size && cross(hull[current], hull[next], hull[(antipodal + 1) % size])
            > cross(hull[current], hull[next], hull[antipodal]) {
            antipodal = (antipodal + 1) % size;
            advances += 1;
        }
        let after = (antipodal + 1) % size;
        maximum_squared = maximum_squared.max(distance_squared(hull[current], hull[antipodal]));
        maximum_squared = maximum_squared.max(distance_squared(hull[next], hull[antipodal]));
        maximum_squared = maximum_squared.max(distance_squared(hull[current], hull[after]));
        maximum_squared = maximum_squared.max(distance_squared(hull[next], hull[after]));
    }
    (maximum_squared as f64).sqrt()
}
