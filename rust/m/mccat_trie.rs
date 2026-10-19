const MAX_WORDS: usize = 64;
const MAX_WORD_LENGTH: usize = 32;
const MAX_INPUT_VALUES: usize = 1 + MAX_WORDS * (1 + MAX_WORD_LENGTH);
const MAX_NODES: usize = MAX_WORDS * MAX_WORD_LENGTH;
const MAX_OUTPUT_BYTES: usize = MAX_WORDS * (MAX_WORD_LENGTH + 1);

#[derive(Clone, Copy, Default)]
struct TrieNode {
    value: u8,
    terminal: bool,
    postfix: usize,
    other_char: usize,
}

fn new_node(nodes: &mut [TrieNode; MAX_NODES + 1], used: &mut usize, value: u8) -> usize {
    *used += 1;
    nodes[*used].value = value;
    *used
}

fn new_suffix(nodes: &mut [TrieNode; MAX_NODES + 1], used: &mut usize,
              values: &[i64], start: usize, length: usize) -> usize {
    let root = new_node(nodes, used, values[start] as u8);
    let mut current = root;
    for offset in 1..length {
        let child = new_node(nodes, used, values[start + offset] as u8);
        nodes[current].postfix = child;
        current = child;
    }
    nodes[current].terminal = true;
    root
}

fn insert_word(nodes: &mut [TrieNode; MAX_NODES + 1], used: &mut usize, current: usize,
               values: &[i64], start: usize, length: usize, offset: usize) {
    if nodes[current].value == values[start + offset] as u8 {
        if offset + 1 == length {
            nodes[current].terminal = true;
        } else {
            let next = nodes[current].postfix;
            if next == 0 {
                nodes[current].postfix = new_suffix(nodes, used, values, start + offset + 1, length - offset - 1);
            } else {
                insert_word(nodes, used, next, values, start, length, offset + 1);
            }
        }
    } else {
        let next = nodes[current].other_char;
        if next == 0 {
            nodes[current].other_char = new_suffix(nodes, used, values, start + offset, length - offset);
        } else {
            insert_word(nodes, used, next, values, start, length, offset);
        }
    }
}

fn measure_output(nodes: &[TrieNode; MAX_NODES + 1], current: usize, depth: usize, length: &mut usize) {
    if current == 0 { return; }
    if nodes[current].terminal { *length += depth + 2; }
    measure_output(nodes, nodes[current].postfix, depth + 1, length);
    measure_output(nodes, nodes[current].other_char, depth, length);
}

fn emit_output(nodes: &[TrieNode; MAX_NODES + 1], current: usize, depth: usize,
               prefix: &mut [u8; MAX_WORD_LENGTH], output: &mut [u8], position: &mut usize) {
    if current == 0 { return; }
    prefix[depth] = nodes[current].value;
    if nodes[current].terminal {
        for byte in prefix.iter().take(depth + 1) { output[*position] = *byte; *position += 1; }
        output[*position] = b'\n';
        *position += 1;
    }
    emit_output(nodes, nodes[current].postfix, depth + 1, prefix, output, position);
    emit_output(nodes, nodes[current].other_char, depth, prefix, output, position);
}

#[no_mangle]
pub unsafe extern "C" fn mccat_trie(input: *const i64, length: usize,
                                      output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_WORDS as i64 { return -1; }
    let word_count = values[0] as usize;
    let mut starts = [0usize; MAX_WORDS];
    let mut lengths = [0usize; MAX_WORDS];
    let mut position = 1usize;
    for index in 0..word_count {
        if position >= length { return -1; }
        let word_length_value = values[position];
        position += 1;
        if word_length_value < 1 || word_length_value > MAX_WORD_LENGTH as i64 { return -1; }
        let word_length = word_length_value as usize;
        if word_length > length - position { return -1; }
        starts[index] = position;
        lengths[index] = word_length;
        for value in &values[position..position + word_length] {
            if !(33..=126).contains(value) { return -1; }
        }
        position += word_length;
    }
    if position != length { return -1; }

    let mut nodes = [TrieNode::default(); MAX_NODES + 1];
    let mut used = 0usize;
    let mut root = 0usize;
    for index in 0..word_count {
        if root == 0 { root = new_suffix(&mut nodes, &mut used, values, starts[index], lengths[index]); }
        else { insert_word(&mut nodes, &mut used, root, values, starts[index], lengths[index], 0); }
    }
    let mut output_length = 0usize;
    measure_output(&nodes, root, 0, &mut output_length);
    if output_length > MAX_OUTPUT_BYTES { return -1; }
    if output_length != 0 && (output.is_null() || capacity < output_length) { return -2; }
    if output_length == 0 { return 0; }
    let out = std::slice::from_raw_parts_mut(output, capacity);
    let mut prefix = [0u8; MAX_WORD_LENGTH];
    let mut written = 0usize;
    emit_output(&nodes, root, 0, &mut prefix, out, &mut written);
    written as i64
}
