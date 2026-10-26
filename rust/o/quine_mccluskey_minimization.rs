const MAX_VARIABLES: usize = 3;
const MAX_CUBES: usize = 27;
const MAX_STATES: usize = 256;
const MAX_INPUT_LENGTH: usize = 9;
const INF: usize = 99;

fn valid_cube(care: usize, value: usize, status: *const i64, size: usize) -> (bool, u32) {
    let mut cover = 0u32;
    for minterm in 0..size {
        if (minterm & care) == value {
            let state = unsafe { *status.add(minterm) };
            if state == 0 { return (false, 0); }
            if state == 1 { cover |= 1u32 << minterm; }
        }
    }
    (cover != 0, cover)
}

fn lex_better(candidate: u32, incumbent: u32, count: usize) -> bool {
    for index in 0..count {
        let left = candidate & (1u32 << index) != 0;
        let right = incumbent & (1u32 << index) != 0;
        if left != right { return left; }
    }
    false
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(), output.add(offset), 8);
}

#[no_mangle]
pub unsafe extern "C" fn quine_mccluskey_minimization(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let n_value = *input;
    if n_value < 1 || n_value > MAX_VARIABLES as i64 { return -1; }
    let n = n_value as usize;
    let size = 1usize << n;
    if length != 1 + size { return -1; }
    for minterm in 0..size {
        let state = *input.add(1 + minterm);
        if state < 0 || state > 2 { return -1; }
    }

    let mut cares = [0usize; MAX_CUBES];
    let mut values = [0usize; MAX_CUBES];
    let mut covers = [0u32; MAX_CUBES];
    let mut literal_counts = [0usize; MAX_CUBES];
    let mut prime_count = 0usize;
    let full = size - 1;
    for care in 0..=full {
        for value in 0..=full {
            if value & !care != 0 { continue; }
            let (valid, cover) = valid_cube(care, value, input.add(1), size);
            if !valid { continue; }
            let mut prime = true;
            for variable in 0..n {
                let bit = 1usize << variable;
                if care & bit != 0 && valid_cube(care ^ bit, value & !bit, input.add(1), size).0 {
                    prime = false;
                    break;
                }
            }
            if prime {
                cares[prime_count] = care;
                values[prime_count] = value;
                covers[prime_count] = cover;
                literal_counts[prime_count] = care.count_ones() as usize;
                prime_count += 1;
            }
        }
    }
    let mut on_mask = 0usize;
    for minterm in 0..size {
        if *input.add(1 + minterm) == 1 { on_mask |= 1usize << minterm; }
    }
    let state_count = 1usize << size;
    let mut term_cost = [INF; MAX_STATES];
    let mut literal_cost = [INF; MAX_STATES];
    let mut selected = [0u32; MAX_STATES];
    term_cost[0] = 0;
    literal_cost[0] = 0;
    for index in 0..prime_count {
        let prime_bit = 1u32 << index;
        for state in (0..state_count).rev() {
            if term_cost[state] == INF { continue; }
            let destination = state | covers[index] as usize;
            if destination == state { continue; }
            let new_terms = term_cost[state] + 1;
            let new_literals = literal_cost[state] + literal_counts[index];
            let new_selected = selected[state] | prime_bit;
            let mut better = new_terms < term_cost[destination];
            if new_terms == term_cost[destination] {
                better = new_literals < literal_cost[destination];
                if new_literals == literal_cost[destination] {
                    better = lex_better(new_selected, selected[destination], prime_count);
                }
            }
            if better {
                term_cost[destination] = new_terms;
                literal_cost[destination] = new_literals;
                selected[destination] = new_selected;
            }
        }
    }
    let chosen = selected[on_mask];
    let mut term_count = 0usize;
    for index in 0..prime_count {
        if chosen & (1u32 << index) != 0 { term_count += 1; }
    }
    let output_bytes = 8 * (1 + 2 * term_count);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut cursor = 0usize;
    store_i64_le(output, cursor * 8, term_count as i64);
    cursor += 1;
    for index in 0..prime_count {
        if chosen & (1u32 << index) != 0 {
            store_i64_le(output, cursor * 8, cares[index] as i64);
            cursor += 1;
            store_i64_le(output, cursor * 8, values[index] as i64);
            cursor += 1;
        }
    }
    output_bytes as i64
}
