const MAX_VERTICES: usize = 8;
const MAX_ARCS: i64 = 24;
const MAX_INPUT_LENGTH: usize = 77;
const MAX_CAPACITY: i64 = 15;

#[no_mangle]
pub unsafe extern "C" fn synchronous_round_push_relabel(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (raw_n, raw_m, raw_source, raw_sink) = (values[0], values[1], values[2], values[3]);
    if !(2..=MAX_VERTICES as i64).contains(&raw_n) || !(0..=MAX_ARCS).contains(&raw_m)
        || raw_source < 0 || raw_source >= raw_n || raw_sink < 0 || raw_sink >= raw_n
        || raw_source == raw_sink || length != 4 + 3 * raw_m as usize { return -1; }
    let n = raw_n as usize;
    let m = raw_m as usize;
    let source = raw_source as usize;
    let sink = raw_sink as usize;
    let mut capacity = [[0_i64; MAX_VERTICES]; MAX_VERTICES];
    for index in 0..m {
        let offset = 4 + 3 * index;
        let (u, v, c) = (values[offset], values[offset + 1], values[offset + 2]);
        if u < 0 || u >= raw_n || v < 0 || v >= raw_n || u == v || c < 0 || c > MAX_CAPACITY {
            return -1;
        }
        capacity[u as usize][v as usize] += c;
    }

    let mut residual = capacity;
    let mut excess = [0_i64; MAX_VERTICES];
    let mut height = [0_usize; MAX_VERTICES];
    height[source] = n;
    for v in 0..n {
        if v == source { continue; }
        let amount = residual[source][v];
        if amount != 0 {
            residual[source][v] = 0;
            residual[v][source] += amount;
            excess[source] -= amount;
            excess[v] += amount;
        }
    }

    loop {
        let mut active = [0_usize; MAX_VERTICES];
        let mut active_count = 0_usize;
        for v in 0..n {
            if v != source && v != sink && excess[v] > 0 && height[v] < n {
                active[active_count] = v;
                active_count += 1;
            }
        }
        if active_count == 0 { return excess[sink]; }

        let mut change = [0_i64; MAX_VERTICES];
        for active_index in 0..active_count {
            let u = active[active_index];
            let mut remaining = excess[u];
            for v in 0..n {
                if remaining <= 0 { break; }
                if residual[u][v] > 0 && height[u] == height[v] + 1 {
                    let amount = remaining.min(residual[u][v]);
                    residual[u][v] -= amount;
                    residual[v][u] += amount;
                    change[u] -= amount;
                    change[v] += amount;
                    remaining -= amount;
                }
            }
        }

        let mut next_excess = excess;
        let mut next_height = height;
        for v in 0..n { next_excess[v] += change[v]; }
        for active_index in 0..active_count {
            let u = active[active_index];
            if next_excess[u] <= 0 { continue; }
            let minimum = (0..n).filter(|&v| residual[u][v] > 0)
                .map(|v| height[v]).min();
            next_height[u] = minimum.map_or(n + 1, |value| value + 1);
        }
        excess = next_excess;
        height = next_height;
    }
}
