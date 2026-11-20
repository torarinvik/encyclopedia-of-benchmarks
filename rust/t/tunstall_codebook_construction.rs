const MAX_S: i64 = 4_222_124_650_659_840;
const RESULT_FACTOR: i64 = MAX_S + 1;

#[no_mangle]
pub unsafe extern "C" fn tunstall_codebook_construction(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 7 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=4).contains(&values[0]) || !(2..=4).contains(&values[1]) { return -1; }
    let k = values[0] as usize;
    let bits = values[1] as usize;
    if length != k + 2 { return -1; }
    let mut weights = [0i64; 4];
    let mut total = 0i64;
    for symbol in 0..k {
        let weight = values[2 + symbol];
        if weight <= 0 || weight > 8 { return -1; }
        weights[symbol] = weight;
        total += weight;
    }
    if total > 8 { return -1; }

    let mut powers = [0i64; 17];
    powers[0] = 1;
    for exponent in 1..=16 { powers[exponent] = powers[exponent - 1] * total; }
    let cap = 1usize << bits;
    let mut target = cap;
    while (target - 1) % (k - 1) != 0 { target -= 1; }

    let mut products = [0i64; 31];
    let mut depths = [0usize; 31];
    let mut phrase_keys = [0u64; 31];
    let mut leaves = [0usize; 16];
    let mut node_count = 1usize;
    let mut leaf_count = 0usize;
    for symbol in 0..k {
        let node = node_count;
        node_count += 1;
        products[node] = weights[symbol];
        depths[node] = 1;
        phrase_keys[node] = ((symbol + 1) as u64) << 56;
        leaves[leaf_count] = node;
        leaf_count += 1;
    }

    let mut scaled_expectation = powers[16];
    while leaf_count < target {
        let mut best_position = 0usize;
        let mut best_node = leaves[0];
        let mut best_probability = products[best_node] * powers[15 - depths[best_node]];
        for position in 1..leaf_count {
            let candidate = leaves[position];
            let probability = products[candidate] * powers[15 - depths[candidate]];
            if probability > best_probability ||
                (probability == best_probability && phrase_keys[candidate] < phrase_keys[best_node]) {
                best_position = position;
                best_node = candidate;
                best_probability = probability;
            }
        }

        scaled_expectation += products[best_node] * powers[16 - depths[best_node]];
        leaf_count -= 1;
        leaves[best_position] = leaves[leaf_count];
        for symbol in 0..k {
            let child = node_count;
            node_count += 1;
            products[child] = products[best_node] * weights[symbol];
            depths[child] = depths[best_node] + 1;
            let shift = 4 * (14 - depths[best_node]);
            phrase_keys[child] = phrase_keys[best_node] | (((symbol + 1) as u64) << shift);
            leaves[leaf_count] = child;
            leaf_count += 1;
        }
    }
    if scaled_expectation > MAX_S { return -1; }
    target as i64 * RESULT_FACTOR + scaled_expectation
}
