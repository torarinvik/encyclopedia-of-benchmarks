const MAX_ITEMS: usize = 5;
const MAX_ATOMS: usize = 3;
const MAX_INPUT: usize = 43;
const MAX_OUTPUT_WORDS: usize = 9;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

fn density_before(left: usize, right: usize, reward: &[i64; MAX_ITEMS],
                  fit: &[i64; MAX_ITEMS], mean: &[i64; MAX_ITEMS]) -> bool {
    let left_score = reward[left] * fit[left] * mean[right];
    let right_score = reward[right] * fit[right] * mean[left];
    left_score > right_score || (left_score == right_score && left < right)
}

#[no_mangle]
pub unsafe extern "C" fn stochastic_knapsack_greedy(
    input_opt: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input_opt.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input_opt, length);
    let n_raw = input[0];
    let bound_raw = input[1];
    if n_raw < 1 || n_raw > MAX_ITEMS as i64 || bound_raw < 1 || bound_raw > 8 { return -1; }
    let n = n_raw as usize;
    let bound = bound_raw as usize;
    let mut rewards = [0i64; MAX_ITEMS];
    let mut atom_counts = [0usize; MAX_ITEMS];
    let mut denominators = [0i64; MAX_ITEMS];
    let mut fits = [0i64; MAX_ITEMS];
    let mut means = [0i64; MAX_ITEMS];
    let mut sizes = [[0i64; MAX_ATOMS]; MAX_ITEMS];
    let mut weights = [[0i64; MAX_ATOMS]; MAX_ITEMS];
    let mut position = 2usize;
    for item in 0..n {
        if position + 2 > length { return -1; }
        let reward = input[position]; position += 1;
        let atom_count_raw = input[position]; position += 1;
        if !(0..=20).contains(&reward) || atom_count_raw < 1 || atom_count_raw > MAX_ATOMS as i64 { return -1; }
        rewards[item] = reward;
        atom_counts[item] = atom_count_raw as usize;
        for atom in 0..atom_counts[item] {
            if position + 2 > length { return -1; }
            let size = input[position]; position += 1;
            let weight = input[position]; position += 1;
            if size < 0 || size > bound as i64 + 1 || weight < 1 || weight > 3 { return -1; }
            sizes[item][atom] = size;
            weights[item][atom] = weight;
            denominators[item] += weight;
            if size <= bound as i64 { fits[item] += weight; }
            means[item] += size.min(bound as i64) * weight;
        }
        if denominators[item] > 9 || means[item] == 0 { return -1; }
    }
    if position != length { return -1; }

    let mut order = [0usize; MAX_ITEMS];
    for i in 0..n {
        let mut j = i;
        while j > 0 && density_before(i, order[j - 1], &rewards, &fits, &means) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = i;
    }
    let mut best_single = 0usize;
    for i in 1..n {
        let left = rewards[i] * fits[i] * denominators[best_single];
        let right = rewards[best_single] * fits[best_single] * denominators[i];
        if left > right { best_single = i; }
    }
    let mut joint_denominator = 1i64;
    let mut scenario_count = 1usize;
    for i in 0..n {
        joint_denominator *= denominators[i];
        scenario_count *= atom_counts[i];
    }
    let mut singleton_score = 0i64;
    let mut order_score = 0i64;
    for scenario in 0..scenario_count {
        let mut digits = scenario;
        let mut scenario_weight = 1i64;
        let mut selected_size = [0i64; MAX_ITEMS];
        for item in 0..n {
            let atom = digits % atom_counts[item];
            digits /= atom_counts[item];
            selected_size[item] = sizes[item][atom];
            scenario_weight *= weights[item][atom];
        }
        if selected_size[best_single] <= bound as i64 {
            singleton_score += scenario_weight * rewards[best_single];
        }
        let mut used = 0i64;
        let mut earned = 0i64;
        for rank in 0..n {
            let item = order[rank];
            if used + selected_size[item] > bound as i64 { break; }
            used += selected_size[item];
            earned += rewards[item];
        }
        order_score += scenario_weight * earned;
    }

    let use_order = order_score > singleton_score;
    let output_count = if use_order { n } else { 1 };
    let mut staged = [0i64; MAX_OUTPUT_WORDS];
    staged[0] = if use_order { 1 } else { 0 };
    staged[1] = output_count as i64;
    for i in 0..output_count { staged[2 + i] = if use_order { order[i] as i64 } else { best_single as i64 }; }
    staged[2 + output_count] = if use_order { order_score } else { singleton_score };
    staged[3 + output_count] = joint_denominator;
    let words = output_count + 4;
    let bytes = words * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for word in 0..words { store_i64_le(output, word * 8, staged[word]); }
    bytes as i64
}
