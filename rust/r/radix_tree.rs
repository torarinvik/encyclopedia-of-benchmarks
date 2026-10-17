const MAX_OPERATIONS: usize = 256;
const MAX_WORD_LENGTH: usize = 32;
const MAX_ROOT_PREFIX_LENGTH: usize = MAX_OPERATIONS * MAX_WORD_LENGTH;
const MAX_NODES: usize = 1 + 2 * MAX_OPERATIONS;
const MAX_VALID_INPUT_LENGTH: usize = 8705;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 8706;

#[derive(Clone, Copy)]
struct Node {
    prefix: [u8; MAX_WORD_LENGTH],
    prefix_len: usize,
    children: [u16; 26],
    is_leaf: bool,
}

impl Default for Node {
    fn default() -> Self { Self { prefix: [0; MAX_WORD_LENGTH], prefix_len: 0, children: [0; 26], is_leaf: false } }
}

fn allocate_node(nodes: &mut [Node; MAX_NODES], node_count: &mut usize, prefix: &[u8], is_leaf: bool) -> usize {
    if *node_count >= MAX_NODES { return 0; }
    let index = *node_count;
    *node_count += 1;
    nodes[index].prefix[..prefix.len()].copy_from_slice(prefix);
    nodes[index].prefix_len = prefix.len();
    nodes[index].is_leaf = is_leaf;
    index
}

fn insert(nodes: &mut [Node; MAX_NODES], node_count: &mut usize, root_prefix: &[u8; MAX_ROOT_PREFIX_LENGTH], root_prefix_len: usize, node_index: usize, word: &[u8]) -> bool {
    if word.is_empty() { nodes[node_index].is_leaf = true; return true; }
    let equal_prefix = if node_index == 0 {
        root_prefix_len == word.len() && root_prefix[..root_prefix_len] == word[..]
    } else {
        nodes[node_index].prefix_len == word.len() && nodes[node_index].prefix[..nodes[node_index].prefix_len] == word[..]
    };
    if equal_prefix && !nodes[node_index].is_leaf {
        nodes[node_index].is_leaf = true;
        return true;
    }
    let letter = usize::from(word[0] - b'a');
    let encoded_child = nodes[node_index].children[letter];
    if encoded_child == 0 {
        let child = allocate_node(nodes, node_count, word, true);
        if child == 0 { return false; }
        nodes[node_index].children[letter] = (child + 1) as u16;
        return true;
    }
    let child = usize::from(encoded_child - 1);
    let child_prefix_len = nodes[child].prefix_len;
    let mut common = 0;
    while common < child_prefix_len && common < word.len() && nodes[child].prefix[common] == word[common] { common += 1; }
    if common == child_prefix_len {
        return insert(nodes, node_count, root_prefix, root_prefix_len, child, &word[common..]);
    }

    let old_suffix = nodes[child].prefix[common..child_prefix_len].to_vec();
    let intermediate = allocate_node(nodes, node_count, &word[..common], false);
    if intermediate == 0 { return false; }
    nodes[child].prefix[..old_suffix.len()].copy_from_slice(&old_suffix);
    nodes[child].prefix_len = old_suffix.len();
    let old_letter = usize::from(old_suffix[0] - b'a');
    nodes[intermediate].children[old_letter] = (child + 1) as u16;
    nodes[node_index].children[letter] = (intermediate + 1) as u16;
    if common == word.len() { nodes[intermediate].is_leaf = true; true }
    else { insert(nodes, node_count, intermediate, &word[common..]) }
}

fn find(nodes: &[Node; MAX_NODES], node_index: usize, word: &[u8]) -> bool {
    if word.is_empty() { return false; }
    let encoded_child = nodes[node_index].children[usize::from(word[0] - b'a')];
    if encoded_child == 0 { return false; }
    let child = usize::from(encoded_child - 1);
    let prefix_len = nodes[child].prefix_len;
    let mut common = 0;
    while common < prefix_len && common < word.len() && nodes[child].prefix[common] == word[common] { common += 1; }
    if common != prefix_len { return false; }
    if common == word.len() { nodes[child].is_leaf } else { find(nodes, child, &word[common..]) }
}

fn delete(nodes: &mut [Node; MAX_NODES], root_prefix: &mut [u8; MAX_ROOT_PREFIX_LENGTH], root_prefix_len: &mut usize, node_index: usize, word: &[u8]) -> bool {
    if word.is_empty() { return false; }
    let letter = usize::from(word[0] - b'a');
    let encoded_child = nodes[node_index].children[letter];
    if encoded_child == 0 { return false; }
    let child = usize::from(encoded_child - 1);
    let prefix_len = nodes[child].prefix_len;
    let mut common = 0;
    while common < prefix_len && common < word.len() && nodes[child].prefix[common] == word[common] { common += 1; }
    if common != prefix_len { return false; }
    if common != word.len() { return delete(nodes, root_prefix, root_prefix_len, child, &word[common..]); }
    if !nodes[child].is_leaf { return false; }

    let child_count = nodes[child].children.iter().filter(|&&entry| entry != 0).count();
    if child_count == 0 {
        nodes[node_index].children[letter] = 0;
        let mut remaining = 0;
        let mut survivor = 0;
        for (index, &entry) in nodes[node_index].children.iter().enumerate() {
            if entry != 0 { remaining += 1; survivor = usize::from(entry - 1); }
        }
        if remaining == 1 && !nodes[node_index].is_leaf {
            let survivor_prefix_len = nodes[survivor].prefix_len;
            let survivor_is_leaf = nodes[survivor].is_leaf;
            let survivor_children = nodes[survivor].children;
            if node_index == 0 {
                if *root_prefix_len + survivor_prefix_len > MAX_ROOT_PREFIX_LENGTH { return false; }
                root_prefix[*root_prefix_len..*root_prefix_len + survivor_prefix_len].copy_from_slice(&nodes[survivor].prefix[..survivor_prefix_len]);
                *root_prefix_len += survivor_prefix_len;
            } else {
                let survivor_prefix = nodes[survivor].prefix[..survivor_prefix_len].to_vec();
                let parent_prefix_len = nodes[node_index].prefix_len;
                nodes[node_index].prefix[parent_prefix_len..parent_prefix_len + survivor_prefix_len].copy_from_slice(&survivor_prefix);
                nodes[node_index].prefix_len += survivor_prefix_len;
            }
            nodes[node_index].is_leaf = survivor_is_leaf;
            nodes[node_index].children = survivor_children;
        }
    } else if child_count > 1 {
        nodes[child].is_leaf = false;
    } else {
        let survivor = usize::from(*nodes[child].children.iter().find(|&&entry| entry != 0).unwrap() - 1);
        let survivor_prefix_len = nodes[survivor].prefix_len;
        let survivor_prefix = nodes[survivor].prefix[..survivor_prefix_len].to_vec();
        let survivor_is_leaf = nodes[survivor].is_leaf;
        let survivor_children = nodes[survivor].children;
        let child_prefix_len = nodes[child].prefix_len;
        nodes[child].prefix[child_prefix_len..child_prefix_len + survivor_prefix_len].copy_from_slice(&survivor_prefix);
        nodes[child].prefix_len += survivor_prefix_len;
        nodes[child].is_leaf = survivor_is_leaf;
        nodes[child].children = survivor_children;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn radix_tree_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH || length > MAX_VALID_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = values[0] as usize;
    let mut nodes = [Node::default(); MAX_NODES];
    let mut node_count = 1_usize;
    let mut root_prefix = [0_u8; MAX_ROOT_PREFIX_LENGTH];
    let mut root_prefix_len = 0_usize;
    let mut checksum = 0_i64;
    let mut cursor = 1_usize;
    for operation in 0..operation_count {
        if cursor + 2 > length { return -1; }
        let opcode = values[cursor];
        let word_length_value = values[cursor + 1];
        cursor += 2;
        if !(0..=2).contains(&opcode) || !(1..=MAX_WORD_LENGTH as i64).contains(&word_length_value) { return -1; }
        let word_length = word_length_value as usize;
        if cursor + word_length > length { return -1; }
        let mut word = [0_u8; MAX_WORD_LENGTH];
        for index in 0..word_length {
            let byte = values[cursor + index];
            if !(97..=122).contains(&byte) { return -1; }
            word[index] = byte as u8;
        }
        cursor += word_length;
        if opcode == 0 {
            if !insert(&mut nodes, &mut node_count, &root_prefix, root_prefix_len, 0, &word[..word_length]) { return -1; }
        } else {
            let observed = if opcode == 1 { find(&nodes, 0, &word[..word_length]) } else { delete(&mut nodes, &mut root_prefix, &mut root_prefix_len, 0, &word[..word_length]) };
            checksum += (operation as i64 + 1) * (1 + if observed { 1_i64 } else { 0_i64 });
        }
    }
    if cursor != length { return -1; }
    checksum
}
