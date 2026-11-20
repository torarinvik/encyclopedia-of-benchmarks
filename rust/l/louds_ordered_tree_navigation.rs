const MAX_NODES: usize = 32;
const MAX_QUERIES: usize = 32;
const MAX_INPUT_WORDS: usize = 130;
const MAX_OUTPUT_WORDS: usize = 4 + MAX_QUERIES;

#[no_mangle]
pub unsafe extern "C" fn louds_ordered_tree_navigation(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_WORDS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (nodes_value, queries_value) = (values[0], values[1]);
    if !(1..=MAX_NODES as i64).contains(&nodes_value)
        || !(0..=MAX_QUERIES as i64).contains(&queries_value) { return -1; }
    let nodes = nodes_value as usize;
    let queries = queries_value as usize;
    if length != 2 + (nodes - 1) + 3 * queries { return -1; }

    let mut parent = [-1i64; MAX_NODES];
    for vertex in 1..nodes {
        let value = values[1 + vertex];
        if value < 0 || value >= vertex as i64 { return -1; }
        parent[vertex] = value;
    }

    let query_base = nodes + 1;
    for index in 0..queries {
        let offset = query_base + 3 * index;
        let (opcode, node, argument) =
            (values[offset], values[offset + 1], values[offset + 2]);
        if node < 0 || node >= nodes as i64 { return -1; }
        if opcode == 0 || opcode == 1 {
            if argument != 0 { return -1; }
        } else if opcode == 2 {
            if argument < 0 || argument > nodes as i64 { return -1; }
        } else {
            return -1;
        }
    }

    let mut level_order = [0usize; MAX_NODES];
    let mut order_count = 1usize;
    let mut order_cursor = 0usize;
    while order_cursor < order_count {
        let vertex = level_order[order_cursor];
        order_cursor += 1;
        for child in 1..nodes {
            if parent[child] == vertex as i64 {
                level_order[order_count] = child;
                order_count += 1;
            }
        }
    }
    if order_count != nodes { return -1; }

    let mut degrees = [0usize; MAX_NODES];
    let mut packed = 0u64;
    let mut bit_length = 0usize;
    for node in 0..nodes {
        let vertex = level_order[node];
        degrees[node] = (1..nodes).filter(|&child| parent[child] == vertex as i64).count();
        for _ in 0..degrees[node] {
            packed |= 1u64 << bit_length;
            bit_length += 1;
        }
        bit_length += 1; // terminating zero
    }

    let mut decoded_degrees = [0usize; MAX_NODES];
    let mut rank_prefix = [0usize; MAX_NODES + 1];
    let mut bit_position = 0usize;
    let mut previous_zero = None;
    for node in 0..nodes {
        while bit_position < bit_length && (packed >> bit_position) & 1 != 0 {
            bit_position += 1;
        }
        if bit_position >= bit_length { return -1; }
        decoded_degrees[node] = match previous_zero {
            Some(previous) => bit_position - previous - 1,
            None => bit_position,
        };
        rank_prefix[node + 1] = rank_prefix[node] + decoded_degrees[node];
        previous_zero = Some(bit_position);
        bit_position += 1;
    }

    let mut words = [0i64; MAX_OUTPUT_WORDS];
    words[0] = nodes as i64;
    words[1] = bit_length as i64;
    words[2] = packed as i64;
    words[3] = queries as i64;
    for index in 0..queries {
        let offset = query_base + 3 * index;
        let (opcode, node, argument) =
            (values[offset], values[offset + 1] as usize, values[offset + 2]);
        words[4 + index] = if opcode == 0 {
            decoded_degrees[node] as i64
        } else if opcode == 1 {
            if node == 0 { -1 } else {
                let mut parent_node = -1;
                for candidate in 0..nodes {
                    if rank_prefix[candidate + 1] >= node {
                        parent_node = candidate as i64;
                        break;
                    }
                }
                parent_node
            }
        } else {
            let degree = decoded_degrees[node];
            if argument as usize >= degree { -1 }
            else { (1 + rank_prefix[node] + argument as usize) as i64 }
        };
    }

    let output_words = 4 + queries;
    let output_bytes = output_words * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for (index, word) in words[..output_words].iter().enumerate() {
        let bytes = word.to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 8), 8);
    }
    output_bytes as i64
}
