const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const MAX_ITERATIONS: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 132;
const SCORE_SCALE: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn hits_fixed_point(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let m_value = values[1];
    let k_value = values[2];
    if !(1..=MAX_VERTICES as i64).contains(&n_value)
        || !(0..=MAX_EDGES as i64).contains(&m_value)
        || !(0..=MAX_ITERATIONS as i64).contains(&k_value)
    {
        return -1;
    }

    let n = n_value as usize;
    let m = m_value as usize;
    let iterations = k_value as usize;
    if length != 3 + 2 * m {
        return -1;
    }

    let mut sources = [0usize; MAX_EDGES];
    let mut targets = [0usize; MAX_EDGES];
    let mut seen = [false; MAX_VERTICES * MAX_VERTICES];
    for edge in 0..m {
        let source_value = values[3 + 2 * edge];
        let target_value = values[4 + 2 * edge];
        if source_value < 0 || source_value >= n_value
            || target_value < 0 || target_value >= n_value
            || source_value == target_value
        {
            return -1;
        }
        let source = source_value as usize;
        let target = target_value as usize;
        let slot = source * MAX_VERTICES + target;
        if seen[slot] {
            return -1;
        }
        seen[slot] = true;
        sources[edge] = source;
        targets[edge] = target;
    }

    let mut hubs = [0i64; MAX_VERTICES];
    let mut authorities = [0i64; MAX_VERTICES];
    hubs[..n].fill(SCORE_SCALE);

    for _ in 0..iterations {
        let mut raw_authorities = [0i64; MAX_VERTICES];
        for edge in 0..m {
            raw_authorities[targets[edge]] += hubs[sources[edge]];
        }
        let authority_total: i64 = raw_authorities[..n].iter().sum();
        if authority_total == 0 {
            authorities[..n].fill(0);
        } else {
            for vertex in 0..n {
                authorities[vertex] = raw_authorities[vertex] * SCORE_SCALE / authority_total;
            }
        }

        let mut raw_hubs = [0i64; MAX_VERTICES];
        for edge in 0..m {
            raw_hubs[sources[edge]] += authorities[targets[edge]];
        }
        let hub_total: i64 = raw_hubs[..n].iter().sum();
        if hub_total == 0 {
            hubs[..n].fill(0);
        } else {
            for vertex in 0..n {
                hubs[vertex] = raw_hubs[vertex] * SCORE_SCALE / hub_total;
            }
        }
    }

    let mut result = 0i64;
    for vertex in 0..n {
        result += (vertex as i64 + 1)
            * (authorities[vertex] + 65_537 * hubs[vertex]);
    }
    result
}
