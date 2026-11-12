const MAX_QUERIES: usize = 32;
const MAX_NODES: usize = MAX_QUERIES + 2;
const ALPHABET: usize = 26;

#[derive(Clone, Copy)]
struct Node {
    length: i32,
    link: usize,
    next: [i32; ALPHABET],
}

fn extendable(nodes: &[Node; MAX_NODES], text: &[i32], position: usize, mut node: usize) -> usize {
    loop {
        let preceding = position as i32 - nodes[node].length - 1;
        if preceding >= 0 && text[preceding as usize] == text[position] {
            return node;
        }
        node = nodes[node].link;
    }
}

fn summarize(text: &[i32]) -> (i64, i64, i64) {
    let mut nodes = [Node { length: 0, link: 0, next: [-1; ALPHABET] }; MAX_NODES];
    nodes[0].length = -1;
    let mut node_count = 2usize;
    let mut last = 1usize;
    let mut longest_prefix = 0i64;
    for position in 0..text.len() {
        let letter = text[position] as usize;
        let parent = extendable(&nodes, text, position, last);
        let mut child = nodes[parent].next[letter];
        if child < 0 {
            let new_child = node_count;
            node_count += 1;
            nodes[new_child].length = nodes[parent].length + 2;
            if nodes[new_child].length == 1 {
                nodes[new_child].link = 1;
            } else {
                let suffix_parent = extendable(&nodes, text, position, nodes[parent].link);
                nodes[new_child].link = nodes[suffix_parent].next[letter] as usize;
            }
            nodes[parent].next[letter] = new_child as i32;
            child = new_child as i32;
        }
        last = child as usize;
        if nodes[last].length == position as i32 + 1 {
            longest_prefix = position as i64 + 1;
        }
    }
    (node_count as i64 - 2, longest_prefix, nodes[last].length as i64)
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn palindromes_in_deque(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > 1 + 2 * MAX_QUERIES {
        return -1;
    }
    let query_value = *input;
    if query_value < 1 || query_value > MAX_QUERIES as i64 {
        return -1;
    }
    let queries = query_value as usize;
    if length != 1 + 2 * queries {
        return -1;
    }

    let mut size = 0i32;
    for query in 0..queries {
        let operation = *input.add(1 + 2 * query);
        let letter = *input.add(2 + 2 * query);
        if operation == 0 || operation == 1 {
            if letter < 0 || letter >= ALPHABET as i64 {
                return -1;
            }
            size += 1;
        } else if operation == 2 || operation == 3 {
            if letter != 0 || size == 0 {
                return -1;
            }
            size -= 1;
        } else {
            return -1;
        }
    }
    if output.is_null() || capacity < 24 * queries {
        return -2;
    }

    let mut text = [0i32; MAX_QUERIES];
    size = 0;
    for query in 0..queries {
        let operation = *input.add(1 + 2 * query) as i32;
        let letter = *input.add(2 + 2 * query) as i32;
        if operation == 0 {
            for index in (1..=size as usize).rev() {
                text[index] = text[index - 1];
            }
            text[0] = letter;
            size += 1;
        } else if operation == 1 {
            text[size as usize] = letter;
            size += 1;
        } else if operation == 2 {
            for index in 1..size as usize {
                text[index - 1] = text[index];
            }
            size -= 1;
        } else {
            size -= 1;
        }
        let (distinct, prefix, suffix) = summarize(&text[..size as usize]);
        let offset = 24 * query;
        store_i64_le(output, offset, distinct);
        store_i64_le(output, offset + 8, prefix);
        store_i64_le(output, offset + 16, suffix);
    }
    (24 * queries) as i64
}
