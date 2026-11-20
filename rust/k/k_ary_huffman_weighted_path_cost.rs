#[no_mangle]
pub unsafe extern "C" fn k_ary_huffman_weighted_path_cost(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(3..=13).contains(&length) {
        return -1;
    }
    let arity_value = unsafe { *input };
    let count_value = unsafe { *input.add(1) };
    if (arity_value != 3 && arity_value != 4) || !(1..=10).contains(&count_value) {
        return -1;
    }
    let arity = arity_value as usize;
    let count = count_value as usize;
    if length != count + 2 || (count > 1 && (count - 1) % (arity - 1) != 0) {
        return -1;
    }

    let mut weights = [0i64; 16];
    let mut active = [false; 16];
    for index in 0..count {
        let weight = unsafe { *input.add(index + 2) };
        if !(0..=1000).contains(&weight) {
            return -1;
        }
        weights[index] = weight;
        active[index] = true;
    }

    let mut node_count = count;
    let mut active_count = count;
    let mut cost = 0i64;
    while active_count > 1 {
        let mut combined = 0i64;
        for _ in 0..arity {
            let mut best: Option<usize> = None;
            for index in 0..node_count {
                if !active[index] {
                    continue;
                }
                let is_better = match best {
                    None => true,
                    Some(prior) => {
                        weights[index] < weights[prior]
                            || (weights[index] == weights[prior] && index < prior)
                    }
                };
                if is_better {
                    best = Some(index);
                }
            }
            let Some(best_index) = best else { return -1 };
            combined += weights[best_index];
            active[best_index] = false;
            active_count -= 1;
        }
        cost += combined;
        weights[node_count] = combined;
        active[node_count] = true;
        node_count += 1;
        active_count += 1;
    }
    cost
}
