use std::ptr;

const MAX_TEXT: usize = 256;
const MAX_QUERIES: usize = 128;
const MAX_STATES: usize = 2 * MAX_TEXT;
const MAX_INPUT_LENGTH: usize = 33_283;
const MAX_VALID_INPUT_LENGTH: usize = 33_282;
const ALPHABET: usize = 128;

#[derive(Clone, Copy)]
struct State {
    length: usize,
    link: i32,
    next: [i32; ALPHABET],
}

const EMPTY_STATE: State = State { length: 0, link: -1, next: [-1; ALPHABET] };

fn build_automaton(states: &mut [State; MAX_STATES], text: &[usize]) -> usize {
    states[0] = EMPTY_STATE;
    let mut state_count = 1usize;
    let mut last = 0usize;
    for &symbol in text {
        let current = state_count;
        state_count += 1;
        states[current] = EMPTY_STATE;
        states[current].length = states[last].length + 1;
        let mut previous = last as i32;
        while previous != -1 && states[previous as usize].next[symbol] == -1 {
            states[previous as usize].next[symbol] = current as i32;
            previous = states[previous as usize].link;
        }
        if previous == -1 {
            states[current].link = 0;
        } else {
            let next_state = states[previous as usize].next[symbol] as usize;
            if states[previous as usize].length + 1 == states[next_state].length {
                states[current].link = next_state as i32;
            } else {
                let clone = state_count;
                state_count += 1;
                states[clone] = states[next_state];
                states[clone].length = states[previous as usize].length + 1;
                while previous != -1 && states[previous as usize].next[symbol] == next_state as i32 {
                    states[previous as usize].next[symbol] = clone as i32;
                    previous = states[previous as usize].link;
                }
                states[next_state].link = clone as i32;
                states[current].link = clone as i32;
            }
        }
        last = current;
    }
    state_count
}

fn find_state(states: &[State; MAX_STATES], pattern: &[usize]) -> Option<usize> {
    let mut current = 0usize;
    for &symbol in pattern {
        let next = states[current].next[symbol];
        if next == -1 { return None; }
        current = next as usize;
    }
    Some(current)
}

fn count_occurrences(states: &[State; MAX_STATES], state_count: usize,
                     text: &[usize], pattern: &[usize]) -> i64 {
    let Some(pattern_state) = find_state(states, pattern) else { return 0; };
    let mut occurrences = [0i64; MAX_STATES];
    let mut by_length = [0usize; MAX_TEXT + 1];
    let mut order = [0usize; MAX_STATES];
    for state in 0..state_count { by_length[states[state].length] += 1; }
    for length in 1..=text.len() { by_length[length] += by_length[length - 1]; }
    for state in (0..state_count).rev() {
        let length = states[state].length;
        by_length[length] -= 1;
        order[by_length[length]] = state;
    }
    let mut last = 0usize;
    for &symbol in text {
        last = states[last].next[symbol] as usize;
        occurrences[last] = 1;
    }
    for index in (0..state_count).rev() {
        let state = order[index];
        let link = states[state].link;
        if link != -1 { occurrences[link as usize] += occurrences[state]; }
    }
    occurrences[pattern_state]
}

fn count_distinct_substrings(states: &[State; MAX_STATES], state_count: usize) -> i64 {
    let mut total = 0i64;
    for state in 1..state_count {
        let link = states[state].link as usize;
        total += (states[state].length - states[link].length) as i64;
    }
    total
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { ptr::write(output.add(offset + byte), (bits >> (8 * byte)) as u8); }
}

#[no_mangle]
pub unsafe extern "C" fn suffix_automaton(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_TEXT as i64 { return -1; }
    let text_length = values[0] as usize;
    let query_count_index = text_length + 1;
    if length <= query_count_index || values[query_count_index] < 0 || values[query_count_index] > MAX_QUERIES as i64 { return -1; }
    let query_count = values[query_count_index] as usize;
    if length > MAX_VALID_INPUT_LENGTH { return -1; }
    let mut text = [0usize; MAX_TEXT];
    for i in 0..text_length {
        let symbol = values[i + 1];
        if !(0..ALPHABET as i64).contains(&symbol) { return -1; }
        text[i] = symbol as usize;
    }
    let text_slice = &text[..text_length];
    let mut states = [EMPTY_STATE; MAX_STATES];
    let state_count = build_automaton(&mut states, text_slice);
    let mut results = [0i64; MAX_QUERIES];
    let mut opcodes = [0u8; MAX_QUERIES];
    let mut cursor = query_count_index + 1;
    for query in 0..query_count {
        if cursor + 1 >= length { return -1; }
        let opcode_value = values[cursor]; cursor += 1;
        let pattern_length_value = values[cursor]; cursor += 1;
        if !(0..=2).contains(&opcode_value) || !(0..=MAX_TEXT as i64).contains(&pattern_length_value) { return -1; }
        let opcode = opcode_value as usize;
        let pattern_length = pattern_length_value as usize;
        if opcode == 2 && pattern_length != 0 { return -1; }
        if pattern_length > length - cursor { return -1; }
        let mut pattern = [0usize; MAX_TEXT];
        for i in 0..pattern_length {
            let symbol = values[cursor]; cursor += 1;
            if !(0..ALPHABET as i64).contains(&symbol) { return -1; }
            pattern[i] = symbol as usize;
        }
        opcodes[query] = opcode as u8;
        let pattern_slice = &pattern[..pattern_length];
        results[query] = match opcode {
            0 => find_state(&states, pattern_slice).is_some() as i64,
            1 => count_occurrences(&states, state_count, text_slice, pattern_slice),
            _ => count_distinct_substrings(&states, state_count),
        };
    }
    if cursor != length { return -1; }
    let output_bytes = query_count * 9;
    if output.is_null() || capacity < output_bytes { return -2; }
    for query in 0..query_count {
        ptr::write(output.add(query * 9), opcodes[query]);
        store_i64_le(output, query * 9 + 1, results[query]);
    }
    output_bytes as i64
}
