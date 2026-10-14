// Fixed-capacity lowercase trie with set semantics and subtree word counts.
const MAX_VALUES: usize = 1024;
const MAX_WORD_LENGTH: usize = 128;
const NODE_CAPACITY: usize = 1024;
const ALPHABET_SIZE: usize = 26;
const HASH_MOD: i64 = 1_000_000_007;
const OFFSET: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn trie_benchmark(values: *const i64, length: usize) -> i64 {
    if length > MAX_VALUES { return -1; }
    let mut children = [0usize; NODE_CAPACITY * ALPHABET_SIZE];
    let mut terminal = [false; NODE_CAPACITY];
    let mut subtree_words = [0usize; NODE_CAPACITY];
    let mut used_nodes = 1usize;
    let mut position = 0usize;
    let mut operation = 0usize;
    let mut checksum = 0i64;
    let mut active_hash_sum = 0i64;

    while position < length {
        if position + 1 >= length { return -1; }
        let opcode = *values.add(position);
        let word_length_value = *values.add(position + 1);
        if !(0..=5).contains(&opcode) || word_length_value < 0 ||
            word_length_value > MAX_WORD_LENGTH as i64 { return -1; }
        let word_length = word_length_value as usize;
        if opcode == 5 && word_length != 0 { return -1; }
        if word_length > length - position - 2 { return -1; }

        let mut word_hash = word_length as i64 + 1;
        for i in 0..word_length {
            let character = *values.add(position + 2 + i);
            if !(97..=122).contains(&character) { return -1; }
            word_hash = (word_hash * 31 + character - 96) % HASH_MOD;
        }

        let mut node = 1usize;
        let mut observed = 0i64;
        if opcode == 0 {
            for i in 0..word_length {
                let letter = (*values.add(position + 2 + i) - 97) as usize;
                let edge = (node - 1) * ALPHABET_SIZE + letter;
                let mut child = children[edge];
                if child == 0 {
                    if used_nodes == NODE_CAPACITY { return -1; }
                    used_nodes += 1;
                    child = used_nodes;
                    children[edge] = child;
                }
                node = child;
            }
            if !terminal[node - 1] {
                terminal[node - 1] = true;
                node = 1;
                subtree_words[node - 1] += 1;
                for i in 0..word_length {
                    let letter = (*values.add(position + 2 + i) - 97) as usize;
                    node = children[(node - 1) * ALPHABET_SIZE + letter];
                    subtree_words[node - 1] += 1;
                }
                active_hash_sum += word_hash;
                observed = 1;
            }
        } else {
            let mut traversed = 0usize;
            while traversed < word_length && node != 0 {
                let letter = (*values.add(position + 2 + traversed) - 97) as usize;
                node = children[(node - 1) * ALPHABET_SIZE + letter];
                traversed += 1;
            }
            if traversed != word_length { node = 0; }
            if opcode == 1 {
                if node != 0 && terminal[node - 1] {
                    terminal[node - 1] = false;
                    node = 1;
                    subtree_words[node - 1] -= 1;
                    for i in 0..word_length {
                        let letter = (*values.add(position + 2 + i) - 97) as usize;
                        node = children[(node - 1) * ALPHABET_SIZE + letter];
                        subtree_words[node - 1] -= 1;
                    }
                    active_hash_sum -= word_hash;
                    observed = 1;
                }
            } else if opcode == 2 {
                observed = i64::from(node != 0 && terminal[node - 1]);
            } else if opcode == 3 {
                observed = i64::from(node != 0 && subtree_words[node - 1] != 0);
            } else if opcode == 4 {
                observed = if node == 0 { 0 } else { subtree_words[node - 1] as i64 };
            } else {
                observed = subtree_words[0] as i64;
            }
        }

        checksum += (operation as i64 + 1) * (observed + OFFSET);
        operation += 1;
        position += 2 + word_length;
    }

    checksum += (operation as i64 + 1) * (active_hash_sum + OFFSET);
    checksum
}
