const MIN_STRINGS: i64 = 2;
const MAX_STRINGS: usize = 8;
const MAX_TOTAL_SYMBOLS: usize = 24;
const MAX_TRIE_NODES: usize = MAX_TOTAL_SYMBOLS + 1;
const MAX_STATES: usize = 49;
const ALPHABET_SIZE: usize = 4;
const MAX_PARSEABLE_LENGTH: usize = 34;

#[derive(Clone, Copy)]
struct GsaState {
    length: usize,
    link: i32,
    next: [usize; ALPHABET_SIZE],
}

#[no_mangle]
pub unsafe extern "C" fn generalized_suffix_automaton_union(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let string_count_value = *input;
    if string_count_value < MIN_STRINGS || string_count_value > MAX_STRINGS as i64 { return -1; }
    let string_count = string_count_value as usize;

    let mut states = [GsaState { length: 0, link: -1, next: [0; ALPHABET_SIZE] }; MAX_STATES];
    let mut trie_next = [[0_usize; ALPHABET_SIZE]; MAX_TRIE_NODES];
    let mut trie_parent = [0_usize; MAX_TRIE_NODES];
    let mut trie_symbol = [0_usize; MAX_TRIE_NODES];
    let mut trie_node_count = 1_usize;
    let mut total_symbols = 0_usize;
    let mut cursor = 1_usize;

    for _ in 0..string_count {
        if cursor >= length { return -1; }
        let string_length_value = *input.add(cursor);
        cursor += 1;
        if !(0..=8).contains(&string_length_value) { return -1; }
        let string_length = string_length_value as usize;
        if total_symbols + string_length > MAX_TOTAL_SYMBOLS || string_length > length - cursor {
            return -1;
        }
        total_symbols += string_length;

        let mut node = 0_usize;
        for offset in 0..string_length {
            let symbol_value = *input.add(cursor + offset);
            if !(0..ALPHABET_SIZE as i64).contains(&symbol_value) { return -1; }
            let symbol = symbol_value as usize;
            let mut child = trie_next[node][symbol];
            if child == 0 {
                if trie_node_count >= MAX_TRIE_NODES { return -1; }
                child = trie_node_count;
                trie_node_count += 1;
                trie_next[node][symbol] = child;
                states[node].next[symbol] = child;
                trie_parent[child] = node;
                trie_symbol[child] = symbol;
            }
            node = child;
        }
        cursor += string_length;
    }
    if cursor != length { return -1; }

    let mut state_count = trie_node_count;
    let mut queue = [0_usize; MAX_TRIE_NODES];
    let (mut queue_head, mut queue_tail) = (0_usize, 0_usize);
    for symbol in 0..ALPHABET_SIZE {
        let child = trie_next[0][symbol];
        if child != 0 {
            queue[queue_tail] = child;
            queue_tail += 1;
        }
    }

    while queue_head < queue_tail {
        let current = queue[queue_head];
        queue_head += 1;
        let parent = trie_parent[current];
        let symbol = trie_symbol[current];
        states[current].length = states[parent].length + 1;

        let mut previous = states[parent].link;
        while previous != -1 && states[previous as usize].next[symbol] == 0 {
            states[previous as usize].next[symbol] = current;
            previous = states[previous as usize].link;
        }
        if previous == -1 {
            states[current].link = 0;
        } else {
            let next_state = states[previous as usize].next[symbol];
            if states[previous as usize].length + 1 == states[next_state].length {
                states[current].link = next_state as i32;
            } else {
                if state_count >= MAX_STATES { return -1; }
                let clone = state_count;
                state_count += 1;
                states[clone].length = states[previous as usize].length + 1;
                states[clone].link = states[next_state].link;
                for character in 0..ALPHABET_SIZE {
                    let destination = states[next_state].next[character];
                    if destination != 0 && states[destination].length > 0 {
                        states[clone].next[character] = destination;
                    }
                }
                while previous != -1 && states[previous as usize].next[symbol] == next_state {
                    states[previous as usize].next[symbol] = clone;
                    previous = states[previous as usize].link;
                }
                states[next_state].link = clone as i32;
                states[current].link = clone as i32;
            }
        }

        for character in 0..ALPHABET_SIZE {
            let child = trie_next[current][character];
            if child != 0 {
                queue[queue_tail] = child;
                queue_tail += 1;
            }
        }
    }

    let mut distinct_count = 0_i64;
    for state in 1..state_count {
        let link = states[state].link as usize;
        distinct_count += (states[state].length - states[link].length) as i64;
    }
    distinct_count
}
