const MAX_LEAVES: usize = 7;
const MAX_EDGES: usize = 11;
const MAX_INPUT: usize = 23;
const MAX_STATES: usize = 945;
const MAX_DEGREE: usize = 8;

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(byte) = (bits >> (8 * byte)) as u8; }
}

fn bit_count(value: u16, n: usize) -> usize {
    let mut count = 0;
    for bit in 0..n { count += ((value >> bit) & 1) as usize; }
    count
}

fn valid_tree(input: &[i64], offset: usize, n: usize, edges: usize) -> bool {
    let mut splits = [0u16; MAX_EDGES];
    let mut internal = [0u16; MAX_EDGES];
    let mut internal_count = 0;
    let universe = (1u16 << n) - 1;
    for edge in 0..edges {
        let raw = input[offset + edge];
        if raw <= 0 || raw as u64 >= universe as u64 || raw & 1 != 0 { return false; }
        splits[edge] = raw as u16;
        for earlier in 0..edge { if splits[earlier] == splits[edge] { return false; } }
        let size = bit_count(splits[edge], n);
        if size == 1 || size == n - 1 {
            if size == n - 1 && splits[edge] != universe ^ 1 { return false; }
        } else if size >= 2 && size <= n - 2 {
            internal[internal_count] = splits[edge];
            internal_count += 1;
        } else { return false; }
    }
    if internal_count != n - 3 { return false; }
    for leaf in 1..n {
        let pendant = 1u16 << leaf;
        let mut found = 0;
        for edge in 0..edges { if splits[edge] == pendant { found += 1; } }
        if found != 1 { return false; }
    }
    let mut root_pendant = 0;
    for edge in 0..edges { if splits[edge] == universe ^ 1 { root_pendant += 1; } }
    if root_pendant != 1 { return false; }
    for i in 0..internal_count {
        for j in i + 1..internal_count {
            let common = internal[i] & internal[j];
            if common != 0 && common != internal[i] && common != internal[j] { return false; }
        }
    }
    true
}

fn sort_state(state: &mut [u16], count: usize) {
    for i in 1..count {
        let value = state[i];
        let mut j = i;
        while j > 0 && state[j - 1] > value { state[j] = state[j - 1]; j -= 1; }
        state[j] = value;
    }
}

unsafe fn same_state(left: *const u16, right: *const u16, edges: usize) -> bool {
    for i in 0..edges { if *left.add(i) != *right.add(i) { return false; } }
    true
}

unsafe fn enumerate_states(leaves: usize, a: *mut u16, b: *mut u16,
                           state_count: &mut usize) -> Option<(*mut u16, usize)> {
    let mut current = a;
    let mut next = b;
    *current.add(0) = 2; *current.add(1) = 4; *current.add(2) = 6;
    *state_count = 1;
    let mut old_edges = 3;
    for size in 4..=leaves {
        let new_edges = old_edges + 2;
        let new_bit = 1u16 << (size - 1);
        let mut next_count = 0;
        for state_index in 0..*state_count {
            let old = current.add(state_index * MAX_EDGES);
            for selected_index in 0..old_edges {
                let selected = *old.add(selected_index);
                let mut candidate = [0u16; MAX_EDGES];
                let mut candidate_count = 0;
                for edge in 0..old_edges {
                    let split = *old.add(edge);
                    if split == selected {
                        candidate[candidate_count] = split; candidate_count += 1;
                        candidate[candidate_count] = split | new_bit; candidate_count += 1;
                    } else if selected & split == selected {
                        candidate[candidate_count] = split | new_bit; candidate_count += 1;
                    } else {
                        candidate[candidate_count] = split; candidate_count += 1;
                    }
                }
                candidate[candidate_count] = new_bit; candidate_count += 1;
                sort_state(&mut candidate, candidate_count);
                let mut found = 0;
                while found < next_count && !same_state(next.add(found * MAX_EDGES), candidate.as_ptr(), new_edges) { found += 1; }
                if found == next_count {
                    if next_count >= MAX_STATES { return None; }
                    for edge in 0..new_edges { *next.add(next_count * MAX_EDGES + edge) = candidate[edge]; }
                    next_count += 1;
                }
            }
        }
        core::mem::swap(&mut current, &mut next);
        *state_count = next_count;
        old_edges = new_edges;
    }
    Some((current, *state_count))
}

#[no_mangle]
pub unsafe extern "C" fn nni_phylogeny_distance(input: *const i64, length: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 7 || length > MAX_INPUT { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    if values[0] < 3 || values[0] > MAX_LEAVES as i64 { return -1; }
    let leaves = values[0] as usize;
    let edges = 2 * leaves - 3;
    if length != 1 + 2 * edges || !valid_tree(values, 1, leaves, edges)
        || !valid_tree(values, 1 + edges, leaves, edges) { return -1; }

    let mut states_a = [0u16; MAX_STATES * MAX_EDGES];
    let mut states_b = [0u16; MAX_STATES * MAX_EDGES];
    let mut state_count = 0;
    let (states, state_count) = match enumerate_states(leaves, states_a.as_mut_ptr(),
        states_b.as_mut_ptr(), &mut state_count) { Some(result) => result, None => return -1 };
    let mut start = [0u16; MAX_EDGES];
    let mut goal = [0u16; MAX_EDGES];
    for i in 0..edges { start[i] = values[1 + i] as u16; goal[i] = values[1 + edges + i] as u16; }
    sort_state(&mut start, edges); sort_state(&mut goal, edges);
    let mut start_index = state_count;
    let mut goal_index = state_count;
    for i in 0..state_count {
        if same_state(states.add(i * MAX_EDGES), start.as_ptr(), edges) { start_index = i; }
        if same_state(states.add(i * MAX_EDGES), goal.as_ptr(), edges) { goal_index = i; }
    }
    if start_index == state_count || goal_index == state_count { return -1; }

    let mut neighbors = [0u16; MAX_STATES * MAX_DEGREE];
    let mut degree = [0u8; MAX_STATES];
    for left in 0..state_count {
        for right in left + 1..state_count {
            let mut common = 0;
            for i in 0..edges {
                let left_size = bit_count(*states.add(left * MAX_EDGES + i), leaves);
                if left_size < 2 || left_size > leaves - 2 { continue; }
                for j in 0..edges {
                    let right_split = *states.add(right * MAX_EDGES + j);
                    let right_size = bit_count(right_split, leaves);
                    if right_size >= 2 && right_size <= leaves - 2
                        && *states.add(left * MAX_EDGES + i) == right_split { common += 1; break; }
                }
            }
            if common + leaves == edges - 1 {
                if degree[left] as usize >= MAX_DEGREE || degree[right] as usize >= MAX_DEGREE { return -1; }
                neighbors[left * MAX_DEGREE + degree[left] as usize] = right as u16;
                degree[left] += 1;
                neighbors[right * MAX_DEGREE + degree[right] as usize] = left as u16;
                degree[right] += 1;
            }
        }
    }
    let mut distance = [-1i16; MAX_STATES];
    let mut queue = [0u16; MAX_STATES];
    let mut head = 0;
    let mut tail = 0;
    distance[start_index] = 0;
    queue[tail] = start_index as u16; tail += 1;
    while head < tail {
        let current = queue[head] as usize; head += 1;
        if current == goal_index { break; }
        for i in 0..degree[current] as usize {
            let next = neighbors[current * MAX_DEGREE + i] as usize;
            if distance[next] < 0 {
                distance[next] = distance[current] + 1;
                queue[tail] = next as u16; tail += 1;
            }
        }
    }
    if distance[goal_index] < 0 { return -1; }
    if output.is_null() || capacity < 8 { return -2; }
    let mut staged = [0u8; 8];
    store_i64_le(staged.as_mut_ptr(), distance[goal_index] as i64);
    for byte in 0..8 { *output.add(byte) = staged[byte]; }
    8
}
