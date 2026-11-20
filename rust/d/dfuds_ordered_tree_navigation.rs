const MAX_N: usize = 31;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 129;
const MAX_BITS: usize = 2 * MAX_N;
const MAX_OUTPUT_WORDS: usize = 4 + MAX_Q;

fn bit_at(bits: u64, position: usize) -> bool {
    (bits >> (position - 1)) & 1 != 0
}

fn find_close(bits: u64, length: usize, start: usize) -> usize {
    let mut balance = 0i32;
    for position in start..=length {
        balance += if bit_at(bits, position) { 1 } else { -1 };
        if balance == 0 { return position; }
    }
    length + 1
}

fn find_open(bits: u64, position: usize) -> usize {
    if bit_at(bits, position) { return position; }
    let mut balance = 0i32;
    for candidate in (1..=position).rev() {
        balance += if bit_at(bits, candidate) { -1 } else { 1 };
        if balance == 0 { return candidate; }
    }
    0
}

fn previous_zero(bits: u64, position: usize) -> usize {
    for candidate in (1..position).rev() {
        if !bit_at(bits, candidate) { return candidate; }
    }
    0
}

#[no_mangle]
pub unsafe extern "C" fn dfuds_ordered_tree_navigation(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, q_value) = (values[0], values[1]);
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) {
        return -1;
    }
    let (n, q) = (n_value as usize, q_value as usize);
    if length != 2 + n - 1 + 3 * q { return -1; }

    let mut parent = [0usize; MAX_N];
    for vertex in 1..n {
        let value = values[1 + vertex];
        if value < 0 || value >= vertex as i64 { return -1; }
        parent[vertex] = value as usize;
    }
    let query_base = n + 1;
    for index in 0..q {
        let offset = query_base + 3 * index;
        let (opcode, node, argument) = (values[offset], values[offset + 1], values[offset + 2]);
        if node < 0 || node >= n_value { return -1; }
        if opcode == 0 || opcode == 2 {
            if argument != 0 { return -1; }
        } else if opcode == 1 {
            if argument < 0 || argument > n_value { return -1; }
        } else { return -1; }
    }

    let mut order = [0usize; MAX_N];
    let mut stack_node = [0usize; MAX_N];
    let mut next_child = [0usize; MAX_N];
    let (mut order_count, mut depth) = (1usize, 1usize);
    next_child[0] = 1;
    while depth > 0 {
        let frame = depth - 1;
        let node = stack_node[frame];
        let mut child = next_child[frame];
        while child < n && parent[child] != node { child += 1; }
        if child < n {
            next_child[frame] = child + 1;
            order[order_count] = child;
            order_count += 1;
            stack_node[depth] = child;
            next_child[depth] = 1;
            depth += 1;
        } else {
            depth -= 1;
        }
    }
    if order_count != n { return -1; }

    let mut descriptor = [0usize; MAX_N];
    let mut position_to_node = [-1i32; MAX_BITS + 2];
    let (mut packed, mut bit_length) = (1u64, 1usize);
    for node in 0..n {
        let degree = (1..n).filter(|&child| parent[child] == order[node]).count();
        descriptor[node] = bit_length + 1;
        position_to_node[descriptor[node]] = node as i32;
        for _ in 0..degree {
            packed |= 1u64 << bit_length;
            bit_length += 1;
        }
        bit_length += 1;
    }
    if bit_length != 2 * n { return -1; }

    let mut words = [0i64; MAX_OUTPUT_WORDS];
    words[0] = n as i64;
    words[1] = bit_length as i64;
    words[2] = packed as i64;
    words[3] = q as i64;
    for index in 0..q {
        let offset = query_base + 3 * index;
        let opcode = values[offset];
        let node = values[offset + 1] as usize;
        let argument = values[offset + 2];
        let start = descriptor[node];
        let mut degree = 0usize;
        while start + degree <= bit_length && bit_at(packed, start + degree) { degree += 1; }
        let mut answer = -1i64;
        if opcode == 0 {
            answer = degree as i64;
        } else if opcode == 1 {
            if (argument as usize) < degree {
                let target = start + degree - (argument as usize + 1);
                let child_start = find_close(packed, bit_length, target) + 1;
                if child_start > MAX_BITS + 1 || position_to_node[child_start] < 0 { return -1; }
                answer = position_to_node[child_start] as i64;
            }
        } else if node != 0 {
            let matched_open = find_open(packed, start - 1);
            let parent_position = previous_zero(packed, matched_open) + 1;
            if parent_position == 1 { answer = 0; }
            else if parent_position <= MAX_BITS + 1 && position_to_node[parent_position] >= 0 {
                answer = position_to_node[parent_position] as i64;
            } else { return -1; }
        }
        words[4 + index] = answer;
    }

    let output_words = 4 + q;
    let required = output_words * 8;
    if output.is_null() || capacity < required { return -2; }
    let output_view = std::slice::from_raw_parts_mut(output, required);
    for (index, word) in words[..output_words].iter().enumerate() {
        output_view[index * 8..index * 8 + 8].copy_from_slice(&word.to_le_bytes());
    }
    required as i64
}
