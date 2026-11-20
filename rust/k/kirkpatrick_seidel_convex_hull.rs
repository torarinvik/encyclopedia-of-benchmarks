const MAX_POINTS: usize = 32;
const MAX_INPUT_VALUES: usize = 66;
const MAX_COORDINATE: i64 = 1_000;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }

#[derive(Clone, Copy, Default)]
struct Slope { dy: i64, dx: i64 }

fn compare_slope(a: Slope, b: Slope) -> std::cmp::Ordering {
    (a.dy * b.dx).cmp(&(b.dy * a.dx))
}

fn insertion_sort_ids(ids: &mut [usize], points: &[Point]) {
    for index in 1..ids.len() {
        let value = ids[index];
        let mut cursor = index;
        while cursor > 0 && points[ids[cursor - 1]].x > points[value].x {
            ids[cursor] = ids[cursor - 1];
            cursor -= 1;
        }
        ids[cursor] = value;
    }
}

fn select_id_by_x(ids: &mut [usize], rank: usize, points: &[Point]) -> usize {
    if ids.len() <= 5 {
        insertion_sort_ids(ids, points);
        return ids[rank];
    }
    let mut medians = [0usize; MAX_POINTS];
    let mut median_count = 0;
    let mut start = 0;
    while start < ids.len() {
        let end = (start + 5).min(ids.len());
        insertion_sort_ids(&mut ids[start..end], points);
        medians[median_count] = ids[start + (end - start - 1) / 2];
        median_count += 1;
        start = end;
    }
    let pivot = select_id_by_x(&mut medians[..median_count], (median_count - 1) / 2, points);
    let mut lower = 0;
    let mut cursor = 0;
    let mut upper = ids.len();
    while cursor < upper {
        if points[ids[cursor]].x < points[pivot].x {
            ids.swap(lower, cursor);
            lower += 1;
            cursor += 1;
        } else if points[ids[cursor]].x > points[pivot].x {
            upper -= 1;
            ids.swap(cursor, upper);
        } else {
            cursor += 1;
        }
    }
    if rank < lower { select_id_by_x(&mut ids[..lower], rank, points) }
    else if rank < upper { pivot }
    else { select_id_by_x(&mut ids[upper..], rank - upper, points) }
}

fn insertion_sort_slopes(values: &mut [Slope]) {
    for index in 1..values.len() {
        let value = values[index];
        let mut cursor = index;
        while cursor > 0 && compare_slope(values[cursor - 1], value).is_gt() {
            values[cursor] = values[cursor - 1];
            cursor -= 1;
        }
        values[cursor] = value;
    }
}

fn select_slope(values: &mut [Slope], rank: usize) -> Slope {
    if values.len() <= 5 {
        insertion_sort_slopes(values);
        return values[rank];
    }
    let mut medians = [Slope::default(); MAX_POINTS];
    let mut median_count = 0;
    let mut start = 0;
    while start < values.len() {
        let end = (start + 5).min(values.len());
        insertion_sort_slopes(&mut values[start..end]);
        medians[median_count] = values[start + (end - start - 1) / 2];
        median_count += 1;
        start = end;
    }
    let pivot = select_slope(&mut medians[..median_count], (median_count - 1) / 2);
    let mut lower = 0;
    let mut cursor = 0;
    let mut upper = values.len();
    while cursor < upper {
        match compare_slope(values[cursor], pivot) {
            std::cmp::Ordering::Less => { values.swap(lower, cursor); lower += 1; cursor += 1; }
            std::cmp::Ordering::Greater => { upper -= 1; values.swap(cursor, upper); }
            std::cmp::Ordering::Equal => cursor += 1,
        }
    }
    if rank < lower { select_slope(&mut values[..lower], rank) }
    else if rank < upper { pivot }
    else { select_slope(&mut values[upper..], rank - upper) }
}

fn pair_slope(first: usize, second: usize, points: &[Point]) -> Slope {
    let (left, right) = if points[first].x < points[second].x { (first, second) } else { (second, first) };
    Slope { dy: points[right].y - points[left].y, dx: points[right].x - points[left].x }
}

fn upper_bridge(points: &[Point], candidates: &mut Vec<usize>, separator: i64) -> (usize, usize) {
    while candidates.len() > 2 {
        let mut slopes: Vec<Slope> = candidates.chunks_exact(2)
            .map(|pair| pair_slope(pair[0], pair[1], points)).collect();
        let slope_rank = (slopes.len() - 1) / 2;
        let median = select_slope(&mut slopes, slope_rank);
        let support_value = |point: Point| point.y * median.dx - median.dy * point.x;
        let support = candidates.iter().map(|&id| support_value(points[id])).max().unwrap();
        let mut left = usize::MAX;
        let mut right = usize::MAX;
        for &id in candidates.iter() {
            if support_value(points[id]) == support {
                if left == usize::MAX || points[id].x < points[left].x { left = id; }
                if right == usize::MAX || points[id].x > points[right].x { right = id; }
            }
        }
        if points[left].x <= separator && separator < points[right].x { return (left, right); }

        let support_is_left = points[right].x <= separator;
        let mut retained = Vec::with_capacity(candidates.len());
        for pair in candidates.chunks_exact(2) {
            let first = pair[0];
            let second = pair[1];
            let order = compare_slope(pair_slope(first, second, points), median);
            if support_is_left {
                if order.is_lt() { retained.extend_from_slice(pair); }
                else { retained.push(if points[first].x > points[second].x { first } else { second }); }
            } else if order.is_gt() {
                retained.extend_from_slice(pair);
            } else {
                retained.push(if points[first].x < points[second].x { first } else { second });
            }
        }
        if candidates.len() % 2 == 1 { retained.push(*candidates.last().unwrap()); }
        *candidates = retained;
    }
    if points[candidates[0]].x < points[candidates[1]].x { (candidates[0], candidates[1]) }
    else { (candidates[1], candidates[0]) }
}

fn append_unique(chain: &mut Vec<usize>, point: usize) {
    if chain.last().copied() != Some(point) { chain.push(point); }
}

fn connect_upper(points: &[Point], candidates: &[usize], left: usize, right: usize,
                 chain: &mut Vec<usize>) {
    if left == right { append_unique(chain, left); return; }
    let mut ids = candidates.to_vec();
    let x_rank = (ids.len() - 1) / 2;
    let separator = points[select_id_by_x(&mut ids, x_rank, points)].x;
    let mut bridge_candidates = candidates.to_vec();
    let (bridge_left, bridge_right) = upper_bridge(points, &mut bridge_candidates, separator);
    let left_set: Vec<usize> = candidates.iter().copied()
        .filter(|&id| points[id].x <= points[bridge_left].x).collect();
    let right_set: Vec<usize> = candidates.iter().copied()
        .filter(|&id| points[id].x >= points[bridge_right].x).collect();
    connect_upper(points, &left_set, left, bridge_left, chain);
    append_unique(chain, bridge_right);
    connect_upper(points, &right_set, bridge_right, right, chain);
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (value as u64 >> (8 * byte)) as u8; }
    }
}

/// Bounded marriage-before-conquest planar convex hull.
#[no_mangle]
pub unsafe extern "C" fn kirkpatrick_seidel_convex_hull(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_VALUES { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 3 || input[0] > MAX_POINTS as i64 { return -1; }
    let count = input[0] as usize;
    if length != 1 + 2 * count { return -1; }
    let mut original = [Point::default(); MAX_POINTS];
    let mut upper_points = [Point::default(); MAX_POINTS];
    let mut lower_points = [Point::default(); MAX_POINTS];
    let mut seen_x = [false; 2 * MAX_COORDINATE as usize + 1];
    for index in 0..count {
        let x = input[1 + 2 * index];
        let y = input[2 + 2 * index];
        if x < -MAX_COORDINATE || x > MAX_COORDINATE || y < -MAX_COORDINATE || y > MAX_COORDINATE { return -1; }
        let slot = (x + MAX_COORDINATE) as usize;
        if seen_x[slot] { return -1; }
        seen_x[slot] = true;
        original[index] = Point { x, y };
        upper_points[index] = Point { x, y };
        lower_points[index] = Point { x, y: -y };
    }
    let non_collinear = (2..count).any(|index|
        (original[1].x - original[0].x) * (original[index].y - original[0].y)
        != (original[1].y - original[0].y) * (original[index].x - original[0].x));
    if !non_collinear { return -1; }

    let ids: Vec<usize> = (0..count).collect();
    let left = (0..count).min_by_key(|&index| original[index].x).unwrap();
    let right = (0..count).max_by_key(|&index| original[index].x).unwrap();
    let mut upper = Vec::new();
    let mut lower = Vec::new();
    connect_upper(&upper_points[..count], &ids, left, right, &mut upper);
    connect_upper(&lower_points[..count], &ids, left, right, &mut lower);
    let mut hull = lower;
    for &index in upper.iter().rev().skip(1).take(upper.len().saturating_sub(2)) {
        append_unique(&mut hull, index);
    }
    let byte_count = 16 * hull.len();
    if output.is_null() || capacity < byte_count { return -2; }
    for (index, &point_id) in hull.iter().enumerate() {
        store_i64_le(output, 16 * index, original[point_id].x);
        store_i64_le(output, 16 * index + 8, original[point_id].y);
    }
    byte_count as i64
}
