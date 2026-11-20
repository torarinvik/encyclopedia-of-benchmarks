const MAX_N: usize = 31;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 129;
const MAX_BITS: usize = 2 * MAX_N;
const MAX_OUTPUT_WORDS: usize = 4 + MAX_Q;

fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn bp_ordered_tree_navigation(
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
    let n = n_value as usize;
    let q = q_value as usize;
    let bit_length = 2 * n;
    if length != 2 + (n - 1) + 3 * q { return -1; }

    let mut parent = [0usize; MAX_N];
    for vertex in 1..n {
        let value = values[1 + vertex];
        if value < 0 || value >= vertex as i64 { return -1; }
        parent[vertex] = value as usize;
    }
    let query_base = n + 1;
    for index in 0..q {
        let offset = query_base + 3 * index;
        let (opcode, first, second) = (values[offset], values[offset + 1], values[offset + 2]);
        if opcode == 0 || opcode == 1 {
            if first < 0 || first > bit_length as i64 ||
                second < -(bit_length as i64) || second > bit_length as i64 { return -1; }
        } else if opcode == 2 {
            if first < 0 || second < first || second >= bit_length as i64 { return -1; }
        } else if (3..=5).contains(&opcode) {
            if first < 0 || first >= bit_length as i64 || second != 0 { return -1; }
        } else { return -1; }
    }

    let mut bits = [0u8; MAX_BITS];
    let mut stack_node = [0usize; MAX_N + 1];
    let mut next_child = [0usize; MAX_N + 1];
    let mut bit_count = 1usize;
    let mut depth = 1usize;
    bits[0] = 1;
    next_child[0] = 1;
    while depth > 0 {
        let frame = depth - 1;
        let node = stack_node[frame];
        let mut child = next_child[frame];
        while child < n && parent[child] != node { child += 1; }
        if child < n {
            next_child[frame] = child + 1;
            bits[bit_count] = 1;
            bit_count += 1;
            stack_node[depth] = child;
            next_child[depth] = 1;
            depth += 1;
        } else {
            bits[bit_count] = 0;
            bit_count += 1;
            depth -= 1;
        }
    }
    if bit_count != bit_length { return -1; }

    let mut excess = [0i64; MAX_BITS + 1];
    let mut packed = 0u64;
    for position in 0..bit_length {
        if bits[position] != 0 {
            packed |= 1u64 << position;
            excess[position + 1] = excess[position] + 1;
        } else {
            excess[position + 1] = excess[position] - 1;
        }
    }
    for index in 0..q {
        let offset = query_base + 3 * index;
        let opcode = values[offset];
        let first = values[offset + 1] as usize;
        if opcode == 3 && bits[first] == 0 { return -1; }
        if opcode == 4 && bits[first] != 0 { return -1; }
        if opcode == 5 && bits[first] == 0 { return -1; }
    }

    let mut words = [0i64; MAX_OUTPUT_WORDS];
    words[0] = n_value;
    words[1] = bit_length as i64;
    words[2] = packed as i64;
    words[3] = q_value;
    for index in 0..q {
        let offset = query_base + 3 * index;
        let opcode = values[offset];
        let first = values[offset + 1] as usize;
        let second = values[offset + 2];
        let mut answer = -1i64;
        if opcode == 0 || opcode == 1 {
            let target = excess[first] + second;
            if opcode == 0 {
                answer = (bit_length + 1) as i64;
                for position in first + 1..=bit_length {
                    if excess[position] == target { answer = position as i64; break; }
                }
            } else {
                answer = 0;
                let mut position = first;
                while position > 0 {
                    position -= 1;
                    if excess[position] == target { answer = position as i64; break; }
                }
            }
        } else if opcode == 2 {
            let right = second as usize;
            let mut best = first;
            for position in first + 1..=right {
                if excess[position + 1] < excess[best + 1] { best = position; }
            }
            answer = best as i64;
        } else if opcode == 3 {
            let target = excess[first + 1] - 1;
            for position in first + 2..=bit_length {
                if excess[position] == target { answer = (position - 1) as i64; break; }
            }
        } else if opcode == 4 {
            let target = excess[first + 1];
            let mut position = first + 1;
            while position > 0 {
                position -= 1;
                if excess[position] == target { answer = position as i64; break; }
            }
        } else if first == 0 {
            answer = -1;
        } else {
            let target = excess[first + 1] - 2;
            let mut position = first + 1;
            while position > 0 {
                position -= 1;
                if excess[position] == target { answer = position as i64; break; }
            }
        }
        words[4 + index] = answer;
    }

    let output_words = 4 + q;
    let required = 8 * output_words;
    if output.is_null() || capacity < required { return -2; }
    for index in 0..output_words {
        write_i64_le(output, 8 * index, words[index]);
    }
    required as i64
}
