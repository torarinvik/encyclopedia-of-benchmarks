const MIN_VERTICES: usize = 3;
const MAX_VERTICES: usize = 12;
const MAX_PARSEABLE_LENGTH: usize = 26;

fn squared_length(x: &[i64; MAX_VERTICES], y: &[i64; MAX_VERTICES], left: usize, right: usize) -> i64 {
    let dx = x[left] - x[right];
    let dy = y[left] - y[right];
    dx * dx + dy * dy
}

#[no_mangle]
pub unsafe extern "C" fn convex_polygon_minimax_length_triangulation(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let count_value = *input;
    if count_value < MIN_VERTICES as i64 || count_value > MAX_VERTICES as i64 { return -1; }
    let count = count_value as usize;
    if length != 1 + 2 * count { return -1; }

    let mut x = [0_i64; MAX_VERTICES];
    let mut y = [0_i64; MAX_VERTICES];
    for vertex in 0..count {
        x[vertex] = *input.add(1 + 2 * vertex);
        y[vertex] = *input.add(2 + 2 * vertex);
        if x[vertex] < -1000 || x[vertex] > 1000 || y[vertex] < -1000 || y[vertex] > 1000 { return -1; }
    }

    let mut area_twice = 0_i64;
    for vertex in 0..count {
        let next = (vertex + 1) % count;
        area_twice += x[vertex] * y[next] - y[vertex] * x[next];
    }
    if area_twice == 0 { return -1; }
    let orientation = if area_twice > 0 { 1_i64 } else { -1_i64 };
    for edge in 0..count {
        let next = (edge + 1) % count;
        let dx = x[next] - x[edge];
        let dy = y[next] - y[edge];
        for vertex in 0..count {
            if vertex == edge || vertex == next { continue; }
            let cross = dx * (y[vertex] - y[edge]) - dy * (x[vertex] - x[edge]);
            if orientation * cross <= 0 { return -1; }
        }
    }

    let mut best = [[0_i64; MAX_VERTICES]; MAX_VERTICES];
    for left in 0..count - 1 {
        best[left][left + 1] = squared_length(&x, &y, left, left + 1);
    }
    for span in 2..count {
        for left in 0..count - span {
            let right = left + span;
            let boundary = squared_length(&x, &y, left, right);
            let mut optimum = i64::MAX;
            for middle in left + 1..right {
                let candidate = best[left][middle].max(best[middle][right]).max(boundary);
                if candidate < optimum { optimum = candidate; }
            }
            best[left][right] = optimum;
        }
    }
    best[0][count - 1]
}
