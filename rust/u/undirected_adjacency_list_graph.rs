const MAX_NODES: usize = 8;
const MAX_OPERATIONS: usize = 24;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 98;
const MAX_OUTPUT_WORDS: usize = 144;

fn push_word(words: &mut [i64; MAX_OUTPUT_WORDS], count: &mut usize, value: i64) {
    words[*count] = value;
    *count += 1;
}

fn push_record(
    words: &mut [i64; MAX_OUTPUT_WORDS],
    count: &mut usize,
    opcode: i64,
    payload: &[i64],
) {
    push_word(words, count, opcode);
    push_word(words, count, payload.len() as i64);
    for &value in payload {
        push_word(words, count, value);
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn undirected_adjacency_list_graph(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=MAX_OPERATIONS as i64).contains(&values[0]) {
        return -1;
    }
    let operation_count = values[0] as usize;
    if input_length != 1 + 4 * operation_count {
        return -1;
    }

    let mut words = [0_i64; MAX_OUTPUT_WORDS];
    let mut word_count = 0_usize;
    let mut edge_weights = [[0_i64; MAX_NODES]; MAX_NODES];
    let mut has_edge = [[false; MAX_NODES]; MAX_NODES];
    let mut node_count = 0_usize;

    for operation_index in 0..operation_count {
        let base = 1 + 4 * operation_index;
        let opcode = values[base];
        let first = values[base + 1];
        let second = values[base + 2];
        let third = values[base + 3];
        if !(0..=4).contains(&opcode) {
            return -1;
        }

        if opcode == 0 || opcode == 4 {
            if first != 0 || second != 0 || third != 0 {
                return -1;
            }
        } else if opcode == 1 {
            if first < i32::MIN as i64 || first > i32::MAX as i64
                || second < i32::MIN as i64 || second > i32::MAX as i64
                || third < i32::MIN as i64 || third > i32::MAX as i64
            {
                return -1;
            }
        } else if opcode == 2 {
            if first < i32::MIN as i64 || first > i32::MAX as i64 || second != 0 || third != 0 {
                return -1;
            }
        } else if first < i32::MIN as i64 || first > i32::MAX as i64
            || second < i32::MIN as i64 || second > i32::MAX as i64 || third != 0
        {
            return -1;
        }

        if opcode == 0 {
            if node_count >= MAX_NODES {
                return -1;
            }
            push_record(&mut words, &mut word_count, opcode, &[node_count as i64]);
            node_count += 1;
        } else if opcode == 1 {
            let mut added = false;
            if first >= 0 && (first as usize) < node_count
                && second >= 0 && (second as usize) < node_count
                && !has_edge[first as usize][second as usize]
            {
                let origin = first as usize;
                let destination = second as usize;
                has_edge[origin][destination] = true;
                has_edge[destination][origin] = true;
                edge_weights[origin][destination] = third;
                edge_weights[destination][origin] = third;
                added = true;
            }
            push_record(&mut words, &mut word_count, opcode, &[if added { 1 } else { 0 }]);
        } else if opcode == 2 {
            if first < 0 || (first as usize) >= node_count {
                return -1;
            }
            let origin = first as usize;
            let mut payload = [0_i64; MAX_NODES + 1];
            let mut neighbor_count = 0_usize;
            for neighbor in 0..node_count {
                if has_edge[origin][neighbor] {
                    payload[neighbor_count + 1] = neighbor as i64;
                    neighbor_count += 1;
                }
            }
            payload[0] = neighbor_count as i64;
            push_record(&mut words, &mut word_count, opcode, &payload[..neighbor_count + 1]);
        } else if opcode == 3 {
            if first < 0 || (first as usize) >= node_count {
                return -1;
            }
            let origin = first as usize;
            let present = second >= 0 && (second as usize) < node_count
                && has_edge[origin][second as usize];
            let weight = if present { edge_weights[origin][second as usize] } else { 0 };
            push_record(
                &mut words,
                &mut word_count,
                opcode,
                &[if present { 1 } else { 0 }, weight],
            );
        } else {
            push_record(&mut words, &mut word_count, opcode, &[node_count as i64]);
        }
    }

    let output_bytes = word_count * 8;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    for index in 0..word_count {
        store_i64_le(output, index * 8, words[index]);
    }
    output_bytes as i64
}
