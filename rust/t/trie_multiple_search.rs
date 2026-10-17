const MAX_OPERATIONS: usize = 64;
const MAX_WORD_LENGTH: usize = 32;
const MAX_WORDS: usize = 32;
const MAX_NODES: usize = 1 + MAX_WORDS * MAX_WORD_LENGTH;
const MAX_VALID_INPUT_LENGTH: usize = 1 + MAX_OPERATIONS * (2 + MAX_WORD_LENGTH);
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_VALID_INPUT_LENGTH + 1;
const FNV_OFFSET: u64 = 14_695_981_039_346_656_037;
const FNV_PRIME: u64 = 1_099_511_628_211;

#[derive(Clone, Copy)]
struct Node {
    children: [usize; 26],
    word_index_plus_one: usize,
}

impl Default for Node {
    fn default() -> Self { Self { children: [0; 26], word_index_plus_one: 0 } }
}

#[derive(Clone, Copy)]
struct Word {
    bytes: [u8; MAX_WORD_LENGTH],
    length: usize,
    frequency: u32,
}

impl Default for Word {
    fn default() -> Self { Self { bytes: [0; MAX_WORD_LENGTH], length: 0, frequency: 0 } }
}

fn hash_byte(hash: &mut u64, byte: u8) {
    *hash = (*hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
}

fn hash_u16(hash: &mut u64, value: u16) {
    for shift in 0..2 { hash_byte(hash, (value >> (shift * 8)) as u8); }
}

fn hash_u32(hash: &mut u64, value: u32) {
    for shift in 0..4 { hash_byte(hash, (value >> (shift * 8)) as u8); }
}

fn word_less(words: &[Word; MAX_WORDS], left: usize, right: usize) -> bool {
    let a = &words[left];
    let b = &words[right];
    for index in 0..a.length.min(b.length) {
        if a.bytes[index] != b.bytes[index] { return a.bytes[index] < b.bytes[index]; }
    }
    a.length < b.length
}

fn begins_with(word: &Word, prefix: &[u8; MAX_WORD_LENGTH], length: usize) -> bool {
    word.length >= length && word.bytes[..length] == prefix[..length]
}

#[no_mangle]
pub unsafe extern "C" fn trie_multiple_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if length > MAX_VALID_INPUT_LENGTH || !(0..=MAX_OPERATIONS as i64).contains(&values[0]) { return -1; }
    let operation_count = values[0] as usize;

    let mut nodes = [Node::default(); MAX_NODES];
    let mut node_count = 1_usize;
    let mut words = [Word::default(); MAX_WORDS];
    let mut word_count = 0_usize;
    let mut hash = FNV_OFFSET;
    hash_u16(&mut hash, operation_count as u16);
    let mut offset = 1_usize;

    for _ in 0..operation_count {
        if offset + 2 > length { return -1; }
        let opcode_value = values[offset];
        let word_length_value = values[offset + 1];
        offset += 2;
        if !(0..=3).contains(&opcode_value) || !(0..=MAX_WORD_LENGTH as i64).contains(&word_length_value) { return -1; }
        let opcode = opcode_value as u8;
        let word_length = word_length_value as usize;
        if opcode == 0 && word_length == 0 { return -1; }
        if offset + word_length > length { return -1; }
        let mut raw = [0_u8; MAX_WORD_LENGTH];
        let mut folded = [0_u8; MAX_WORD_LENGTH];
        for index in 0..word_length {
            let byte = values[offset + index];
            if (65..=90).contains(&byte) {
                raw[index] = byte as u8;
                folded[index] = byte as u8 + 32;
            } else if (97..=122).contains(&byte) {
                raw[index] = byte as u8;
                folded[index] = byte as u8;
            } else { return -1; }
        }
        offset += word_length;
        hash_byte(&mut hash, opcode);

        let mut node = 0_usize;
        let mut matched = 0_usize;
        for &byte in &folded[..word_length] {
            let letter = usize::from(byte - b'a');
            let child = nodes[node].children[letter];
            if child == 0 { break; }
            node = child;
            matched += 1;
        }

        if opcode == 0 {
            let mut insert_node = 0_usize;
            for &byte in &folded[..word_length] {
                let letter = usize::from(byte - b'a');
                let child = nodes[insert_node].children[letter];
                if child == 0 {
                    if node_count >= MAX_NODES { return -1; }
                    let created = node_count;
                    node_count += 1;
                    nodes[insert_node].children[letter] = created;
                    insert_node = created;
                } else { insert_node = child; }
            }
            if nodes[insert_node].word_index_plus_one == 0 {
                let word_index = word_count;
                if word_index >= MAX_WORDS { return -1; }
                words[word_index].bytes = folded;
                words[word_index].length = word_length;
                word_count += 1;
                nodes[insert_node].word_index_plus_one = word_index + 1;
            }
            continue;
        }

        let exact_index = if matched == word_length && nodes[node].word_index_plus_one != 0 {
            Some(nodes[node].word_index_plus_one - 1)
        } else { None };
        if opcode == 1 {
            let present = exact_index.is_some();
            if let Some(index) = exact_index { words[index].frequency += 1; }
            hash_byte(&mut hash, u8::from(present));
            continue;
        }

        let mut suggestions = [0_usize; MAX_WORDS];
        let mut suggestion_count = 0_usize;
        for word_index in 0..word_count {
            if words[word_index].length > matched && begins_with(&words[word_index], &folded, matched) {
                suggestions[suggestion_count] = word_index;
                suggestion_count += 1;
            }
        }
        if let Some(index) = exact_index { words[index].frequency += 1; }
        if opcode == 2 {
            for i in 1..suggestion_count {
                let current = suggestions[i];
                let mut j = i;
                while j > 0 && word_less(&words, current, suggestions[j - 1]) {
                    suggestions[j] = suggestions[j - 1];
                    j -= 1;
                }
                suggestions[j] = current;
            }
        } else {
            for i in 1..suggestion_count {
                let current = suggestions[i];
                let mut j = i;
                while j > 0 {
                    let previous = suggestions[j - 1];
                    let before = words[current].frequency > words[previous].frequency
                        || (words[current].frequency == words[previous].frequency && word_less(&words, previous, current));
                    if !before { break; }
                    suggestions[j] = previous;
                    j -= 1;
                }
                suggestions[j] = current;
            }
        }
        let limit = if opcode == 2 { suggestion_count } else { suggestion_count.min(3) };
        hash_u16(&mut hash, (limit + if exact_index.is_some() { 1 } else { 0 }) as u16);
        if exact_index.is_some() {
            hash_byte(&mut hash, word_length as u8);
            for &byte in &raw[..word_length] { hash_byte(&mut hash, byte); }
        }
        for &word_index in &suggestions[..limit] {
            hash_byte(&mut hash, words[word_index].length as u8);
            for &byte in &words[word_index].bytes[..words[word_index].length] { hash_byte(&mut hash, byte); }
        }
    }
    if offset != length { return -1; }
    hash_u16(&mut hash, word_count as u16);
    let mut order = [0_usize; MAX_WORDS];
    for index in 0..word_count { order[index] = index; }
    for i in 1..word_count {
        let current = order[i];
        let mut j = i;
        while j > 0 && word_less(&words, current, order[j - 1]) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = current;
    }
    for &word_index in &order[..word_count] {
        hash_byte(&mut hash, words[word_index].length as u8);
        for &byte in &words[word_index].bytes[..words[word_index].length] { hash_byte(&mut hash, byte); }
        for shift in 0..4 { hash_byte(&mut hash, (words[word_index].frequency >> (shift * 8)) as u8); }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
