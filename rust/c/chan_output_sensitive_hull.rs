//! Unverified Chan hull draft; no compiler or benchmark has been run.

#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }

fn cross(a: Point, b: Point, c: Point) -> i64 {
    (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x)
}

fn subgroup_hull(points: &[Point], begin: usize, end: usize) -> Vec<usize> {
    let mut order: Vec<usize> = (begin..end).collect();
    order.sort_unstable_by_key(|&i| (points[i].x, points[i].y));
    if order.len() <= 1 { return order; }
    let mut lower = Vec::with_capacity(order.len());
    let mut upper = Vec::with_capacity(order.len());
    for &id in &order {
        while lower.len() >= 2 && cross(points[lower[lower.len()-2]], points[lower[lower.len()-1]], points[id]) <= 0 {
            lower.pop();
        }
        lower.push(id);
    }
    for &id in order.iter().rev() {
        while upper.len() >= 2 && cross(points[upper[upper.len()-2]], points[upper[upper.len()-1]], points[id]) <= 0 {
            upper.pop();
        }
        upper.push(id);
    }
    lower.pop(); upper.pop(); lower.extend(upper); lower
}

fn external_tangent(points: &[Point], hull: &[usize], query_id: usize) -> Option<usize> {
    let query = points[query_id];
    let turn = |a: usize, b: usize| cross(query, points[hull[a]], points[hull[b]]);
    let size = hull.len();
    if size == 1 { return Some(hull[0]); }
    if size == 2 { return Some(hull[if turn(0, 1) > 0 { 0 } else { 1 }]); }
    let initial_up = turn(0, 1) > 0;
    let (mut lo, mut hi) = (0, size);
    while lo < hi {
        let mid = lo + (hi-lo)/2;
        let less_previous = turn(mid, (mid+size-1)%size) > 0;
        let less_next = turn(mid, (mid+1)%size) > 0;
        if less_previous && less_next { return Some(hull[mid]); }
        let before_anchor = mid != 0 && turn(mid, 0) > 0;
        let after_anchor = mid != 0 && turn(0, mid) > 0;
        let search_left = if initial_up { less_next && before_anchor } else { less_next || after_anchor };
        if search_left { hi = mid; } else { lo = mid+1; }
    }
    None
}

fn compute(values: &[i64]) -> Option<Vec<u8>> {
    if values.len() < 7 || values.len() > 66 || !(3..=32).contains(&values[0]) { return None; }
    let n = values[0] as usize;
    if values.len() != 1 + 2*n { return None; }
    let mut points = Vec::with_capacity(n);
    for pair in values[1..].chunks_exact(2) {
        if !(-1000..=1000).contains(&pair[0]) || !(-1000..=1000).contains(&pair[1]) { return None; }
        let point = Point { x: pair[0], y: pair[1] };
        if points.iter().any(|p: &Point| p.x == point.x && p.y == point.y) { return None; }
        points.push(point);
    }
    for i in 0..n { for j in i+1..n { for k in j+1..n {
        if cross(points[i], points[j], points[k]) == 0 { return None; }
    } } }
    let start = (0..n).min_by_key(|&i| (points[i].x, points[i].y))?;
    let mut guess = n.min(4);
    loop {
        let mut groups = Vec::new();
        let mut group_of = vec![0; n];
        let mut position = vec![None; n];
        for begin in (0..n).step_by(guess) {
            let end = n.min(begin+guess);
            let hull = subgroup_hull(&points, begin, end);
            for id in begin..end { group_of[id] = groups.len(); }
            for (index, &id) in hull.iter().enumerate() { position[id] = Some(index); }
            groups.push(hull);
        }
        let mut result = vec![start];
        for _ in 0..guess {
            let current = *result.last()?;
            let mut candidate: Option<usize> = None;
            for (group, hull) in groups.iter().enumerate() {
                let local = if group == group_of[current] {
                    let pos = position[current]?;
                    if hull.len() == 1 { None } else { Some(hull[(pos+1)%hull.len()]) }
                } else { external_tangent(&points, hull, current) };
                if group != group_of[current] && local.is_none() { return None; }
                if let Some(id) = local {
                    if candidate.map_or(true, |old| cross(points[current], points[old], points[id]) < 0) {
                        candidate = Some(id);
                    }
                }
            }
            let next = candidate?;
            if next == start {
                let mut bytes = Vec::with_capacity(result.len()*16);
                for id in result { bytes.extend_from_slice(&points[id].x.to_le_bytes()); bytes.extend_from_slice(&points[id].y.to_le_bytes()); }
                return Some(bytes);
            }
            if result.len() == n { return None; }
            result.push(next);
        }
        if guess == n { return None; }
        guess = n.min(guess*guess);
    }
}

#[no_mangle]
pub unsafe extern "C" fn chan_output_sensitive_hull(input: *const i64, length: usize,
                                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 7 || length > 66 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let bytes = match compute(values) { Some(bytes) => bytes, None => return -1 };
    if output.is_null() || capacity < bytes.len() { return -2; }
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, bytes.len());
    bytes.len() as i64
}
