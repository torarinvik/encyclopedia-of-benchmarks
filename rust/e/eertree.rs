const MAX_TEXT_LENGTH: usize = 128;
const MAX_NODES: usize = MAX_TEXT_LENGTH + 2;
const ALPHABET_SIZE: usize = 26;

#[derive(Clone, Copy)]
struct Node {
    length: i32,
    suffix_link: usize,
    next: [i32; ALPHABET_SIZE],
}

const EMPTY_NODE: Node = Node { length: 0, suffix_link: 0, next: [-1; ALPHABET_SIZE] };

fn find_extendable(nodes: &[Node; MAX_NODES], text: &[i64], position: usize, start: usize) -> usize {
    let mut node = start;
    loop {
        let preceding = position as i32 - 1 - nodes[node].length;
        if preceding >= 0 && text[preceding as usize] == text[position] { return node; }
        node = nodes[node].suffix_link;
    }
}

#[no_mangle]
pub extern "C" fn eertree(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_TEXT_LENGTH + 1).contains(&length) { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&packed[0]) { return -1; }
    let text_length = packed[0] as usize;
    if length != text_length + 1 { return -1; }
    let text = &packed[1..];
    if text.iter().any(|&letter| !(0..ALPHABET_SIZE as i64).contains(&letter)) { return -1; }

    let mut nodes = [EMPTY_NODE; MAX_NODES];
    nodes[0].length = -1;
    nodes[0].suffix_link = 0;
    nodes[1].length = 0;
    nodes[1].suffix_link = 0;
    let mut node_count = 2usize;
    let mut longest_suffix = 1usize;
    let mut checksum = 0i64;

    for position in 0..text_length {
        let letter = text[position] as usize;
        let parent = find_extendable(&nodes, text, position, longest_suffix);
        let mut next = nodes[parent].next[letter];
        if next < 0 {
            next = node_count as i32;
            node_count += 1;
            let new_index = next as usize;
            nodes[new_index] = EMPTY_NODE;
            nodes[new_index].length = nodes[parent].length + 2;
            nodes[parent].next[letter] = next;
            if nodes[new_index].length == 1 {
                nodes[new_index].suffix_link = 1;
            } else {
                let suffix_parent = find_extendable(&nodes, text, position, nodes[parent].suffix_link);
                let suffix = nodes[suffix_parent].next[letter];
                if suffix < 0 { return -1; }
                nodes[new_index].suffix_link = suffix as usize;
            }
        }
        longest_suffix = next as usize;
        checksum += (position as i64 + 1) * (node_count as i64 - 2);
    }
    checksum
}
