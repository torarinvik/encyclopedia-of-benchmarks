//! Unverified divide-and-conquer tangent-merge hull draft.

#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }

fn cross(a: Point, b: Point, c: Point) -> i64 {
    (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x)
}

fn chain(points: &[Point], order: &[usize], upper: bool) -> Vec<usize> {
    if order.len() == 1 { return vec![order[0]]; }
    let middle = order.len()/2;
    let left = chain(points, &order[..middle], upper);
    let right = chain(points, &order[middle..], upper);
    let (mut i, mut j) = (left.len()-1, 0);
    loop {
        let mut changed = false;
        while i > 0 {
            let sign = cross(points[left[i]], points[right[j]], points[left[i-1]]);
            let move_endpoint = if upper { sign > 0 } else { sign < 0 };
            if !move_endpoint { break; }
            i -= 1; changed = true;
        }
        while j+1 < right.len() {
            let sign = cross(points[left[i]], points[right[j]], points[right[j+1]]);
            let move_endpoint = if upper { sign > 0 } else { sign < 0 };
            if !move_endpoint { break; }
            j += 1; changed = true;
        }
        if !changed { break; }
    }
    let mut output = Vec::with_capacity(i+1+right.len()-j);
    output.extend_from_slice(&left[..=i]);
    output.extend_from_slice(&right[j..]);
    output
}

fn compute(values: &[i64]) -> Option<Vec<u8>> {
    if values.len() < 7 || values.len() > 66 || !(3..=32).contains(&values[0]) { return None; }
    let n = values[0] as usize;
    if values.len() != 1+2*n { return None; }
    let mut points: Vec<Point> = Vec::with_capacity(n);
    for pair in values[1..].chunks_exact(2) {
        if !(-1000..=1000).contains(&pair[0]) || !(-1000..=1000).contains(&pair[1]) { return None; }
        if points.iter().any(|point| point.x == pair[0]) { return None; }
        points.push(Point { x: pair[0], y: pair[1] });
    }
    for i in 0..n { for j in i+1..n { for k in j+1..n {
        if cross(points[i], points[j], points[k]) == 0 { return None; }
    } } }
    let mut order: Vec<usize> = (0..n).collect();
    order.sort_unstable_by_key(|&id| points[id].x);
    let lower = chain(&points, &order, false);
    let upper = chain(&points, &order, true);
    let mut output = Vec::with_capacity(16*n);
    for &id in lower.iter().chain(upper[1..upper.len()-1].iter().rev()) {
        output.extend_from_slice(&points[id].x.to_le_bytes());
        output.extend_from_slice(&points[id].y.to_le_bytes());
    }
    Some(output)
}

#[no_mangle]
pub unsafe extern "C" fn divide_conquer_tangent_hull(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 7 || length > 66 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let bytes = match compute(values) { Some(bytes) => bytes, None => return -1 };
    if output.is_null() || capacity < bytes.len() { return -2; }
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, bytes.len());
    bytes.len() as i64
}
