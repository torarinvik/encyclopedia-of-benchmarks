const MAX_INPUT_LENGTH: usize = 83;
const MAX_TEXT_LENGTH: usize = 64;
const MAX_PATTERN_LENGTH: usize = 16;
const MAX_NODES: usize = 1 + MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1) / 2;

fn find_child(first_child: &[i32; MAX_NODES], next_sibling: &[i32; MAX_NODES],
              edge_code: &[u8; MAX_NODES], parent: usize, code: u8) -> Option<usize> {
    let mut child = first_child[parent];
    while child >= 0 {
        let index = child as usize;
        if edge_code[index] == code { return Some(index); }
        child = next_sibling[index];
    }
    None
}

#[no_mangle]
pub unsafe extern "C" fn suffix_trie_search(input: *const i64, input_length: usize) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let (text_length_value, pattern_length_value) = unsafe { (*input, *input.add(1)) };
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length_value) ||
        !(0..=MAX_PATTERN_LENGTH as i64).contains(&pattern_length_value) { return -1; }
    let text_length = text_length_value as usize;
    let pattern_length = pattern_length_value as usize;
    if input_length != 2 + text_length + pattern_length { return -1; }
    let mut text = [0_u8; MAX_TEXT_LENGTH];
    let mut pattern = [0_u8; MAX_PATTERN_LENGTH];
    for index in 0..text_length {
        let code = unsafe { *input.add(2 + index) };
        if !(0..=127).contains(&code) { return -1; }
        text[index] = code as u8;
    }
    for index in 0..pattern_length {
        let code = unsafe { *input.add(2 + text_length + index) };
        if !(0..=127).contains(&code) { return -1; }
        pattern[index] = code as u8;
    }

    let mut first_child = [-1_i32; MAX_NODES];
    let mut next_sibling = [-1_i32; MAX_NODES];
    let mut edge_code = [0_u8; MAX_NODES];
    let mut node_count = 1usize;
    for start in 0..text_length {
        let mut parent = 0usize;
        for position in start..text_length {
            let code = text[position];
            let child = match find_child(&first_child, &next_sibling, &edge_code, parent, code) {
                Some(index) => index,
                None => {
                    let index = node_count;
                    node_count += 1;
                    edge_code[index] = code;
                    next_sibling[index] = first_child[parent];
                    first_child[parent] = index as i32;
                    index
                }
            };
            parent = child;
        }
    }

    let mut node = 0usize;
    for index in 0..pattern_length {
        match find_child(&first_child, &next_sibling, &edge_code, node, pattern[index]) {
            Some(child) => node = child,
            None => return 0,
        }
    }
    1
}
