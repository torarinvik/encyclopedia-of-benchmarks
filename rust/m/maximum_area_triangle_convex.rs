// Independent maximum-area triangle draft; uncompiled and unrun.
fn cross(points: &[i64], a: usize, b: usize, c: usize) -> i64 {
    let (ax, ay) = (points[2 * a], points[2 * a + 1]);
    (points[2 * b] - ax) * (points[2 * c + 1] - ay)
        - (points[2 * b + 1] - ay) * (points[2 * c] - ax)
}

#[no_mangle]
pub unsafe extern "C" fn maximum_area_triangle_convex(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 { return -1; }
    let data = std::slice::from_raw_parts(input, length);
    if !(3..=1024).contains(&data[0]) { return -1; }
    let n = data[0] as usize;
    if length != 1 + 2 * n || data[1..].iter().any(|&x| !(-1_000_000..=1_000_000).contains(&x)) {
        return -1;
    }
    let points = &data[1..];
    for i in 0..n {
        let next = (i + 1) % n;
        for j in 0..n {
            if j != i && j != next && cross(points, i, next, j) <= 0 { return -1; }
        }
    }
    let mut best = 0;
    for i in 0..n - 2 {
        for j in i + 1..n - 1 {
            let (mut lo, mut hi) = (j + 1, n - 1);
            while lo < hi {
                let mid = lo + (hi - lo) / 2;
                if cross(points, i, j, mid) < cross(points, i, j, mid + 1) { lo = mid + 1; }
                else { hi = mid; }
            }
            best = best.max(cross(points, i, j, lo));
        }
    }
    best
}
