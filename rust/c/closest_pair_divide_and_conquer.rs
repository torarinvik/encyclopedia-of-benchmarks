/// Deterministic closest pair with x-rank divide-and-conquer and a y-ordered strip.
const MAX_POINTS: usize = 1024;

#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }

#[derive(Clone, Copy)]
struct PairResult {
    valid: bool,
    distance_squared: u64,
    first: usize,
    second: usize,
}

fn before(left: usize, right: usize, points: &[Point; MAX_POINTS], by_y: bool) -> bool {
    if by_y {
        if points[left].y != points[right].y { return points[left].y < points[right].y; }
        if points[left].x != points[right].x { return points[left].x < points[right].x; }
    } else {
        if points[left].x != points[right].x { return points[left].x < points[right].x; }
        if points[left].y != points[right].y { return points[left].y < points[right].y; }
    }
    left < right
}

fn sort_indices(indices: &mut [usize; MAX_POINTS], scratch: &mut [usize; MAX_POINTS],
                 begin: usize, end: usize, points: &[Point; MAX_POINTS], by_y: bool) {
    if end - begin < 2 { return; }
    let middle = begin + (end - begin) / 2;
    sort_indices(indices, scratch, begin, middle, points, by_y);
    sort_indices(indices, scratch, middle, end, points, by_y);
    let mut left = begin;
    let mut right = middle;
    let mut output = begin;
    while left < middle && right < end {
        if before(indices[right], indices[left], points, by_y) {
            scratch[output] = indices[right];
            right += 1;
        } else {
            scratch[output] = indices[left];
            left += 1;
        }
        output += 1;
    }
    while left < middle { scratch[output] = indices[left]; left += 1; output += 1; }
    while right < end { scratch[output] = indices[right]; right += 1; output += 1; }
    indices[begin..end].copy_from_slice(&scratch[begin..end]);
}

fn squared_distance(left: usize, right: usize, points: &[Point; MAX_POINTS]) -> u64 {
    let dx = points[left].x - points[right].x;
    let dy = points[left].y - points[right].y;
    (dx * dx) as u64 + (dy * dy) as u64
}

fn choose(left: PairResult, right: PairResult) -> PairResult {
    if !left.valid { return right; }
    if !right.valid { return left; }
    if left.distance_squared < right.distance_squared { return left; }
    if right.distance_squared < left.distance_squared { return right; }
    if left.first < right.first || (left.first == right.first && left.second <= right.second) { return left; }
    right
}

fn candidate(mut left: usize, mut right: usize, points: &[Point; MAX_POINTS]) -> PairResult {
    if left > right { std::mem::swap(&mut left, &mut right); }
    PairResult { valid: true, distance_squared: squared_distance(left, right, points), first: left, second: right }
}

fn search(x_order: &[usize; MAX_POINTS], begin: usize, end: usize,
          y_order: &[usize; MAX_POINTS], y_count: usize, rank: &[usize; MAX_POINTS],
          points: &[Point; MAX_POINTS]) -> PairResult {
    let count = end - begin;
    if count <= 3 {
        let mut best = PairResult { valid: false, distance_squared: 0, first: 0, second: 0 };
        for i in begin..end {
            for j in i + 1..end { best = choose(best, candidate(x_order[i], x_order[j], points)); }
        }
        return best;
    }

    let middle = begin + count / 2;
    let mut y_left = [0usize; MAX_POINTS];
    let mut y_right = [0usize; MAX_POINTS];
    let mut left_count = 0;
    let mut right_count = 0;
    for &point in &y_order[..y_count] {
        if rank[point] < middle {
            y_left[left_count] = point;
            left_count += 1;
        } else {
            y_right[right_count] = point;
            right_count += 1;
        }
    }
    let mut best = choose(
        search(x_order, begin, middle, &y_left, left_count, rank, points),
        search(x_order, middle, end, &y_right, right_count, rank, points));

    let mut strip = [0usize; MAX_POINTS];
    let mut strip_count = 0;
    let middle_x = points[x_order[middle]].x;
    for &point in &y_order[..y_count] {
        let dx = points[point].x - middle_x;
        if (dx * dx) as u64 <= best.distance_squared {
            strip[strip_count] = point;
            strip_count += 1;
        }
    }
    for i in 0..strip_count {
        for j in i + 1..strip_count {
            let dy = points[strip[j]].y - points[strip[i]].y;
            if (dy * dy) as u64 > best.distance_squared { break; }
            best = choose(best, candidate(strip[i], strip[j], points));
        }
    }
    best
}

unsafe fn write_pair(output: *mut u8, pair: PairResult) {
    for byte in 0..4 {
        *output.add(byte) = ((pair.first as u32 >> (8 * byte)) & 0xff) as u8;
        *output.add(4 + byte) = ((pair.second as u32 >> (8 * byte)) & 0xff) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn closest_pair_divide_and_conquer(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values.is_null()) { return -1; }
    let point_count = length / 2;

    let mut points = [Point { x: 0, y: 0 }; MAX_POINTS];
    let mut x_order = [0usize; MAX_POINTS];
    let mut y_order = [0usize; MAX_POINTS];
    let mut rank = [0usize; MAX_POINTS];
    let mut scratch = [0usize; MAX_POINTS];
    for index in 0..point_count {
        let x = *values.add(2 * index);
        let y = *values.add(2 * index + 1);
        if !(-1_000_000_000..=1_000_000_000).contains(&x) ||
            !(-1_000_000_000..=1_000_000_000).contains(&y) { return -1; }
        points[index] = Point { x, y };
        x_order[index] = index;
        y_order[index] = index;
    }
    if point_count < 2 { return 0; }
    sort_indices(&mut x_order, &mut scratch, 0, point_count, &points, false);
    for index in 0..point_count { rank[x_order[index]] = index; }

    let mut duplicate = PairResult { valid: false, distance_squared: 0, first: 0, second: 0 };
    let mut group_begin = 0;
    while group_begin < point_count {
        let mut group_end = group_begin + 1;
        let anchor = x_order[group_begin];
        while group_end < point_count &&
            points[x_order[group_end]].x == points[anchor].x &&
            points[x_order[group_end]].y == points[anchor].y { group_end += 1; }
        if group_end - group_begin > 1 {
            let mut first = usize::MAX;
            let mut second = usize::MAX;
            for &id in &x_order[group_begin..group_end] {
                if id < first { second = first; first = id; }
                else if id < second { second = id; }
            }
            duplicate = choose(duplicate, PairResult { valid: true, distance_squared: 0, first, second });
        }
        group_begin = group_end;
    }
    if duplicate.valid {
        if output.is_null() || output_capacity < 8 { return -2; }
        write_pair(output, duplicate);
        return 2;
    }

    sort_indices(&mut y_order, &mut scratch, 0, point_count, &points, true);
    let best = search(&x_order, 0, point_count, &y_order, point_count, &rank, &points);
    if !best.valid { return -1; }
    if output.is_null() || output_capacity < 8 { return -2; }
    write_pair(output, best);
    2
}
