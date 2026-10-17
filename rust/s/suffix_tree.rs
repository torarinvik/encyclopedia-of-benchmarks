const MAX_TEXT_LENGTH: usize = 64;
const MAX_NODES: usize = 1 + 2 * MAX_TEXT_LENGTH;
const MAX_EDGES: usize = 2 * MAX_TEXT_LENGTH;
const MAX_OUTPUT_BYTES: usize = 5176;
const NONE: usize = usize::MAX;

fn append_edge(parent: usize, child: usize, first: &mut [usize; MAX_NODES],
               last: &mut [usize; MAX_NODES], edge_child: &mut [usize; MAX_EDGES],
               edge_next: &mut [usize; MAX_EDGES], edge_count: &mut usize) {
    let edge = *edge_count;
    *edge_count += 1;
    edge_child[edge] = child;
    edge_next[edge] = NONE;
    if last[parent] == NONE {
        first[parent] = edge;
    } else {
        edge_next[last[parent]] = edge;
    }
    last[parent] = edge;
}

fn write_u64(output: &mut [u8; MAX_OUTPUT_BYTES], position: &mut usize, value: u64) {
    for shift in 0..8 {
        output[*position] = (value >> (shift * 8)) as u8;
        *position += 1;
    }
}

/// Build and serialize the pinned Rust compressed suffix-tree node vector.
#[no_mangle]
pub unsafe extern "C" fn suffix_tree_construct(input: *const i64, input_length: usize,
                                                 output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(1..=66).contains(&input_length) { return -1; }
    let text_length_value = unsafe { *input };
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length_value) { return -1; }
    let text_length = text_length_value as usize;
    if input_length != 1 + text_length { return -1; }
    let mut text = [0_u8; MAX_TEXT_LENGTH];
    for index in 0..text_length {
        let code = unsafe { *input.add(1 + index) };
        if !(0..=127).contains(&code) { return -1; }
        text[index] = code as u8;
    }

    let mut labels = [[0_u8; MAX_TEXT_LENGTH]; MAX_NODES];
    let mut label_lengths = [0_usize; MAX_NODES];
    let mut first_edge = [NONE; MAX_NODES];
    let mut last_edge = [NONE; MAX_NODES];
    let mut edge_child = [0_usize; MAX_EDGES];
    let mut edge_next = [NONE; MAX_EDGES];
    let mut node_count = 1_usize;
    let mut edge_count = 0_usize;

    for start in 0..text_length {
        let suffix_length = text_length - start;
        let mut offset = 0_usize;
        let mut node = 0_usize;
        while offset < suffix_length {
            let first_code = text[start + offset];
            let mut selected = first_edge[node];
            while selected != NONE && labels[edge_child[selected]][0] != first_code {
                selected = edge_next[selected];
            }
            if selected == NONE {
                let leaf = node_count;
                node_count += 1;
                let leaf_length = suffix_length - offset;
                labels[leaf][..leaf_length].copy_from_slice(&text[start + offset..text_length]);
                label_lengths[leaf] = leaf_length;
                append_edge(node, leaf, &mut first_edge, &mut last_edge,
                            &mut edge_child, &mut edge_next, &mut edge_count);
                break;
            }

            let child = edge_child[selected];
            let child_length = label_lengths[child];
            let mut common = 0_usize;
            while common < child_length && offset + common < suffix_length &&
                labels[child][common] == text[start + offset + common] {
                common += 1;
            }
            if common == child_length {
                offset += common;
                node = child;
                continue;
            }

            let split = node_count;
            node_count += 1;
            labels[split][..common].copy_from_slice(&labels[child][..common]);
            label_lengths[split] = common;
            let remainder_length = child_length - common;
            for index in 0..remainder_length {
                labels[child][index] = labels[child][common + index];
            }
            label_lengths[child] = remainder_length;
            edge_child[selected] = split;
            append_edge(split, child, &mut first_edge, &mut last_edge,
                        &mut edge_child, &mut edge_next, &mut edge_count);
            offset += common;
            node = split;
        }
    }

    let mut bytes = [0_u8; MAX_OUTPUT_BYTES];
    let mut written = 0_usize;
    write_u64(&mut bytes, &mut written, node_count as u64);
    for node in 0..node_count {
        let label_length = label_lengths[node];
        write_u64(&mut bytes, &mut written, label_length as u64);
        bytes[written..written + label_length].copy_from_slice(&labels[node][..label_length]);
        written += label_length;
        let mut child_count = 0_u64;
        let mut edge = first_edge[node];
        while edge != NONE {
            child_count += 1;
            edge = edge_next[edge];
        }
        write_u64(&mut bytes, &mut written, child_count);
        edge = first_edge[node];
        while edge != NONE {
            write_u64(&mut bytes, &mut written, edge_child[edge] as u64);
            edge = edge_next[edge];
        }
    }
    if output.is_null() || output_capacity < written { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, written); }
    written as i64
}
