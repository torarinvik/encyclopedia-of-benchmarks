const MAX_CITIES: usize = 7;
const CONQUER_THRESHOLD: usize = 3;
const SCALE: f64 = 1000.0;

fn city_distance(x: &[i64; MAX_CITIES], y: &[i64; MAX_CITIES], a: usize, b: usize) -> f64 {
    let dx = (x[a] - x[b]) as f64;
    let dy = (y[a] - y[b]) as f64;
    (dx * dx + dy * dy).sqrt()
}

fn subtree_size(node: usize, count: usize) -> usize {
    if node >= count { return 0; }
    1 + subtree_size(2 * node + 1, count) + subtree_size(2 * node + 2, count)
}

fn collect_postorder(node: usize, count: usize, order: &mut [usize; MAX_CITIES], length: &mut usize) {
    if node >= count { return; }
    collect_postorder(2 * node + 1, count, order, length);
    collect_postorder(2 * node + 2, count, order, length);
    order[*length] = node;
    *length += 1;
}

fn reverse_cycle(start: usize, size: usize, next: &mut [usize; MAX_CITIES], prev: &mut [usize; MAX_CITIES]) {
    let mut current = start;
    for _ in 0..size {
        let old_next = next[current];
        let old_prev = prev[current];
        next[current] = old_prev;
        prev[current] = old_next;
        current = old_next;
    }
}

fn conquer(order: &[usize; MAX_CITIES], count: usize, x: &[i64; MAX_CITIES], y: &[i64; MAX_CITIES],
            next: &mut [usize; MAX_CITIES], prev: &mut [usize; MAX_CITIES]) -> usize {
    let cycle = order[0];
    next[cycle] = cycle;
    prev[cycle] = cycle;
    for point_index in 1..count {
        let point = order[point_index];
        let mut min = cycle;
        let mut mindist = city_distance(x, y, point, cycle);
        let mut tmp = next[cycle];
        while tmp != cycle {
            let test = city_distance(x, y, tmp, point);
            if test < mindist { mindist = test; min = tmp; }
            tmp = next[tmp];
        }
        let next_city = next[min];
        let prev_city = prev[min];
        let min_to_next = city_distance(x, y, min, next_city);
        let min_to_prev = city_distance(x, y, min, prev_city);
        let point_to_next = city_distance(x, y, point, next_city);
        let point_to_prev = city_distance(x, y, point, prev_city);
        if point_to_prev - min_to_prev < point_to_next - min_to_next {
            next[prev_city] = point; prev[point] = prev_city;
            next[point] = min; prev[min] = point;
        } else {
            prev[next_city] = point; next[point] = next_city;
            next[min] = point; prev[point] = min;
        }
    }
    cycle
}

fn merge_cycles(a: usize, b: usize, point: usize, size_a: usize, size_b: usize,
                x: &[i64; MAX_CITIES], y: &[i64; MAX_CITIES],
                next: &mut [usize; MAX_CITIES], prev: &mut [usize; MAX_CITIES]) -> usize {
    let mut min = a;
    let mut mindist = city_distance(x, y, point, a);
    let mut tmp = next[a];
    while tmp != a {
        let test = city_distance(x, y, point, tmp);
        if test < mindist { mindist = test; min = tmp; }
        tmp = next[tmp];
    }
    let mut next_city = next[min];
    let mut prev_city = prev[min];
    let mut min_to_next = city_distance(x, y, min, next_city);
    let mut min_to_prev = city_distance(x, y, min, prev_city);
    let mut point_to_next = city_distance(x, y, point, next_city);
    let mut point_to_prev = city_distance(x, y, point, prev_city);
    let (p1, n1, tton1, ttop1) = if point_to_prev - min_to_prev < point_to_next - min_to_next {
        (prev_city, min, mindist, point_to_prev)
    } else { (min, next_city, point_to_next, mindist) };

    min = b;
    mindist = city_distance(x, y, point, b);
    tmp = next[b];
    while tmp != b {
        let test = city_distance(x, y, point, tmp);
        if test < mindist { mindist = test; min = tmp; }
        tmp = next[tmp];
    }
    next_city = next[min]; prev_city = prev[min];
    min_to_next = city_distance(x, y, min, next_city);
    min_to_prev = city_distance(x, y, min, prev_city);
    point_to_next = city_distance(x, y, point, next_city);
    point_to_prev = city_distance(x, y, point, prev_city);
    let (p2, n2, tton2, ttop2) = if point_to_prev - min_to_prev < point_to_next - min_to_next {
        (prev_city, min, mindist, point_to_prev)
    } else { (min, next_city, point_to_next, mindist) };

    let n1_to_n2 = city_distance(x, y, n1, n2);
    let n1_to_p2 = city_distance(x, y, n1, p2);
    let p1_to_n2 = city_distance(x, y, p1, n2);
    let p1_to_p2 = city_distance(x, y, p1, p2);
    let mut best = ttop1 + ttop2 + n1_to_n2;
    let mut choice = 1;
    let mut test = ttop1 + tton2 + n1_to_p2;
    if test < best { choice = 2; best = test; }
    test = tton1 + ttop2 + p1_to_n2;
    if test < best { choice = 3; best = test; }
    test = tton1 + tton2 + p1_to_p2;
    if test < best { choice = 4; }

    if choice == 1 {
        reverse_cycle(n2, size_b, next, prev);
        next[p1] = point; prev[point] = p1; next[point] = p2; prev[p2] = point;
        next[n2] = n1; prev[n1] = n2;
    } else if choice == 2 {
        next[p1] = point; prev[point] = p1; next[point] = n2; prev[n2] = point;
        next[p2] = n1; prev[n1] = p2;
    } else if choice == 3 {
        next[p2] = point; prev[point] = p2; next[point] = n1; prev[n1] = point;
        next[p1] = n2; prev[n2] = p1;
    } else {
        reverse_cycle(n1, size_a, next, prev);
        next[n1] = point; prev[point] = n1; next[point] = n2; prev[n2] = point;
        next[p2] = p1; prev[p1] = p2;
    }
    point
}

fn solve_subtree(node: usize, count: usize, x: &[i64; MAX_CITIES], y: &[i64; MAX_CITIES],
                 next: &mut [usize; MAX_CITIES], prev: &mut [usize; MAX_CITIES]) -> usize {
    let size = subtree_size(node, count);
    if size <= CONQUER_THRESHOLD {
        let mut order = [0_usize; MAX_CITIES];
        let mut order_count = 0;
        collect_postorder(node, count, &mut order, &mut order_count);
        return conquer(&order, order_count, x, y, next, prev);
    }
    let left = 2 * node + 1;
    let right = 2 * node + 2;
    let left_cycle = solve_subtree(left, count, x, y, next, prev);
    let right_cycle = solve_subtree(right, count, x, y, next, prev);
    merge_cycles(left_cycle, right_cycle, node, subtree_size(left, count), subtree_size(right, count), x, y, next, prev)
}

#[no_mangle]
pub unsafe extern "C" fn olden_tsp(input: *const i64, length: usize) -> i64 {
    if input.is_null() || (length != 7 && length != 15) { return -1; }
    let count_value = *input;
    if count_value != 3 && count_value != 7 { return -1; }
    let count = count_value as usize;
    if length != 1 + 2 * count { return -1; }
    let mut x = [0_i64; MAX_CITIES];
    let mut y = [0_i64; MAX_CITIES];
    let mut next = [0_usize; MAX_CITIES];
    let mut prev = [0_usize; MAX_CITIES];
    for city in 0..count {
        x[city] = *input.add(1 + 2 * city);
        y[city] = *input.add(2 + 2 * city);
        if x[city] < -8 || x[city] > 8 || y[city] < -8 || y[city] > 8 { return -1; }
    }
    solve_subtree(0, count, &x, &y, &mut next, &mut prev);
    let mut tour_length = 0.0;
    let mut city = 0;
    for _ in 0..count {
        let following = next[city];
        tour_length += city_distance(&x, &y, city, following);
        city = following;
    }
    (tour_length * SCALE + 0.5).floor() as i64
}
