const MAX_CITIES: usize = 8;
const MAX_INPUT_VALUES: usize = 17;
const MAX_OUTPUT_VALUES: usize = 11;
const MAX_MASKS: usize = 256;
const INF_COST: f64 = 1.0e300;

#[no_mangle]
pub unsafe extern "C" fn travelling_salesman_dynamic_programming(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let n_value = values[0];
    if !n_value.is_finite() || !(2.0..=MAX_CITIES as f64).contains(&n_value) || n_value.trunc() != n_value { return -1; }
    let n = n_value as usize;
    if input_length != 1 + 2 * n { return -1; }

    let mut x = [0.0_f64; MAX_CITIES];
    let mut y = [0.0_f64; MAX_CITIES];
    for city in 0..n {
        let cx = values[1 + 2 * city];
        let cy = values[2 + 2 * city];
        if !cx.is_finite() || !cy.is_finite() || !(-16.0..=16.0).contains(&cx) ||
            !(-16.0..=16.0).contains(&cy) || cx.trunc() != cx || cy.trunc() != cy { return -1; }
        x[city] = cx;
        y[city] = cy;
    }

    let mut distances = [0.0_f64; MAX_CITIES * MAX_CITIES];
    for from in 0..n {
        for to in 0..n {
            let dx = x[to] - x[from];
            let dy = y[to] - y[from];
            distances[from * MAX_CITIES + to] = (dx * dx + dy * dy).sqrt();
        }
    }

    let mut dp = [INF_COST; MAX_MASKS * MAX_CITIES];
    dp[MAX_CITIES] = 0.0;
    let mask_count = 1_usize << n;
    for mask in 0..mask_count {
        for u in 0..n {
            if mask & (1 << u) == 0 { continue; }
            let prefix = dp[mask * MAX_CITIES + u];
            for v in 0..n {
                let bit = 1_usize << v;
                if mask & bit != 0 { continue; }
                let next_mask = mask | bit;
                let candidate = prefix + distances[u * MAX_CITIES + v];
                if candidate < dp[next_mask * MAX_CITIES + v] {
                    dp[next_mask * MAX_CITIES + v] = candidate;
                }
            }
        }
    }

    let final_mask = mask_count - 1;
    let mut minimum = INF_COST;
    let mut end_node = n;
    for u in 1..n {
        let candidate = dp[final_mask * MAX_CITIES + u] + distances[u * MAX_CITIES];
        if minimum > candidate { minimum = candidate; end_node = u; }
    }
    if end_node == n { return -1; }

    let mut reverse_path = [0_usize; MAX_CITIES + 1];
    let mut path_length = 0;
    let mut mask = final_mask;
    while end_node != 0 {
        reverse_path[path_length] = end_node;
        path_length += 1;
        let previous_mask = mask ^ (1 << end_node);
        let mut found = false;
        for u in 0..n {
            if mask & (1 << u) == 0 { continue; }
            if dp[mask * MAX_CITIES + end_node] ==
                dp[previous_mask * MAX_CITIES + u] + distances[u * MAX_CITIES + end_node] {
                mask = previous_mask;
                end_node = u;
                found = true;
                break;
            }
        }
        if !found || path_length > MAX_CITIES { return -1; }
    }
    reverse_path[path_length] = 0;
    path_length += 1;
    reverse_path[..path_length].reverse();
    reverse_path[path_length] = 0;
    path_length += 1;

    let mut staged = [0.0_f64; MAX_OUTPUT_VALUES];
    staged[0] = path_length as f64;
    for index in 0..path_length { staged[index + 1] = reverse_path[index] as f64; }
    staged[path_length + 1] = minimum;
    let output_size = path_length + 2;
    if output.is_null() || capacity < output_size { return -2; }
    for index in 0..output_size { *output.add(index) = staged[index]; }
    output_size as i64
}
