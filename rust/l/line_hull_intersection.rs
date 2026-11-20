const MAX_VERTICES: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 38;

#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy)]
struct Vector { x: i64, y: i64 }
#[derive(Clone, Copy)]
struct Hit { edge: i64, numerator: i64, denominator: i64 }

fn polar_half(v: Vector) -> i32 {
    if v.y > 0 || (v.y == 0 && v.x >= 0) { 0 } else { 1 }
}
fn angle_before(a: Vector, b: Vector) -> bool {
    let ah = polar_half(a);
    let bh = polar_half(b);
    if ah != bh { return ah < bh; }
    a.x * b.y - a.y * b.x > 0
}
fn rotation_minimum(edges: &[Vector], n: usize) -> usize {
    let (mut low, mut high) = (0, n - 1);
    while low < high {
        let middle = (low + high) / 2;
        if angle_before(edges[middle], edges[high]) { high = middle; }
        else { low = middle + 1; }
    }
    low
}
fn support_edge(edges: &[Vector], n: usize, target: Vector) -> usize {
    let pivot = rotation_minimum(edges, n);
    let (mut low, mut high) = (0, n);
    while low < high {
        let middle = (low + high) / 2;
        if angle_before(edges[(pivot + middle) % n], target) { low = middle + 1; }
        else { high = middle; }
    }
    (pivot + low) % n
}
fn line_value(p: Point, origin: Point, direction: Vector) -> i64 {
    direction.x * (p.y - origin.y) - direction.y * (p.x - origin.x)
}
fn line_parameter(p: Point, origin: Point, direction: Vector) -> i64 {
    (p.x - origin.x) * direction.x + (p.y - origin.y) * direction.y
}
fn crossing(points: &[Point], n: usize, origin: Point, direction: Vector,
            start: usize, end: usize, increasing: bool) -> Hit {
    let span = (end + n - start) % n;
    let (mut low, mut high) = (0, span);
    while high - low > 1 {
        let middle = (low + high) / 2;
        let value = line_value(points[(start + middle) % n], origin, direction);
        if if increasing { value < 0 } else { value > 0 } { low = middle; }
        else { high = middle; }
    }
    let mut index = (start + low) % n;
    if line_value(points[(start + high) % n], origin, direction) == 0 {
        index = (start + high) % n;
    }
    let value = line_value(points[index], origin, direction);
    if value == 0 {
        return Hit { edge: index as i64, numerator: line_parameter(points[index], origin, direction), denominator: 1 };
    }
    let next = (index + 1) % n;
    let next_value = line_value(points[next], origin, direction);
    let mut denominator = value - next_value;
    let edge_dot = (points[next].x - points[index].x) * direction.x
        + (points[next].y - points[index].y) * direction.y;
    let mut numerator = line_parameter(points[index], origin, direction) * denominator + value * edge_dot;
    if denominator < 0 { numerator = -numerator; denominator = -denominator; }
    Hit { edge: index as i64, numerator, denominator }
}
fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn line_hull_intersection(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(3..=MAX_VERTICES as i64).contains(&count_value) { return -1; }
    let n = count_value as usize;
    if length != 5 + 2 * n { return -1; }
    let origin = Point { x: values[1], y: values[2] };
    let line_end = Point { x: values[3], y: values[4] };
    if [origin.x, origin.y, line_end.x, line_end.y].iter().any(|x| !(-50..=50).contains(x)) { return -1; }
    let direction = Vector { x: line_end.x - origin.x, y: line_end.y - origin.y };
    if direction.x == 0 && direction.y == 0 { return -1; }

    let mut points = [Point { x: 0, y: 0 }; MAX_VERTICES];
    let mut edges = [Vector { x: 0, y: 0 }; MAX_VERTICES];
    for i in 0..n {
        points[i] = Point { x: values[5 + 2 * i], y: values[6 + 2 * i] };
        if !(-50..=50).contains(&points[i].x) || !(-50..=50).contains(&points[i].y) { return -1; }
        for j in 0..i {
            if points[j].x == points[i].x && points[j].y == points[i].y { return -1; }
        }
    }
    let mut area2 = 0_i64;
    for i in 0..n {
        let next = (i + 1) % n;
        edges[i] = Vector { x: points[next].x - points[i].x, y: points[next].y - points[i].y };
        area2 += points[i].x * points[next].y - points[next].x * points[i].y;
    }
    if area2 <= 0 { return -1; }
    for i in 0..n {
        let next = (i + 1) % n;
        for j in 0..n {
            if j == i || j == next { continue; }
            let side = edges[i].x * (points[j].y - points[i].y)
                - edges[i].y * (points[j].x - points[i].x);
            if side <= 0 { return -1; }
        }
    }

    let maximum = support_edge(&edges, n, Vector { x: -direction.x, y: -direction.y });
    let minimum = support_edge(&edges, n, direction);
    let max_value = line_value(points[maximum], origin, direction);
    let min_value = line_value(points[minimum], origin, direction);
    let (first, second) = if min_value > 0 || max_value < 0 {
        (-1, -1)
    } else if min_value == 0 || max_value == 0 {
        let touch = if min_value == 0 { minimum } else { maximum };
        let next = (touch + 1) % n;
        let previous = (touch + n - 1) % n;
        if line_value(points[touch], origin, direction) == 0
            && line_value(points[next], origin, direction) == 0 {
            (touch as i64, touch as i64)
        } else if line_value(points[previous], origin, direction) == 0
            && line_value(points[touch], origin, direction) == 0 {
            (previous as i64, previous as i64)
        } else { (touch as i64, -1) }
    } else {
        let a = crossing(&points, n, origin, direction, maximum, minimum, false);
        let b = crossing(&points, n, origin, direction, minimum, maximum, true);
        if a.numerator * b.denominator <= b.numerator * a.denominator { (a.edge, b.edge) }
        else { (b.edge, a.edge) }
    };
    if output.is_null() || capacity < 16 { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, 16);
    store_i64_le(bytes, 0, first);
    store_i64_le(bytes, 8, second);
    16
}
