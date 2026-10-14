// Fixed-capacity lowercase trie with set semantics and subtree word counts.
const MAX_VALUES: usize = 1024;
const MAX_WORD_LENGTH: usize = 128;
const NODE_CAPACITY: usize = 1024;
const ALPHABET_SIZE: usize = 26;
const HASH_MOD: i64 = 1_000_000_007;
const OFFSET: i64 = 1_000_000;

export fn trie_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > MAX_VALUES) return -1;
    var children: [NODE_CAPACITY * ALPHABET_SIZE]usize = undefined;
    var terminal: [NODE_CAPACITY]bool = undefined;
    var subtree_words: [NODE_CAPACITY]usize = undefined;
    for (0..NODE_CAPACITY * ALPHABET_SIZE) |i| { children[i] = 0; }
    for (0..NODE_CAPACITY) |i| { terminal[i] = false; subtree_words[i] = 0; }
    var used_nodes: usize = 1;
    var position: usize = 0;
    var operation: usize = 0;
    var checksum: i64 = 0;
    var active_hash_sum: i64 = 0;

    while (position < length) {
        if (position + 1 >= length) return -1;
        const opcode = values[position];
        const word_length_value = values[position + 1];
        if (opcode < 0 or opcode > 5 or word_length_value < 0 or
            word_length_value > MAX_WORD_LENGTH) return -1;
        const word_length: usize = @intCast(word_length_value);
        if (opcode == 5 and word_length != 0) return -1;
        if (word_length > length - position - 2) return -1;

        var word_hash: i64 = @intCast(word_length + 1);
        for (0..word_length) |i| {
            const character = values[position + 2 + i];
            if (character < 97 or character > 122) return -1;
            word_hash = @mod(word_hash * 31 + character - 96, HASH_MOD);
        }

        var node: usize = 1;
        var observed: i64 = 0;
        if (opcode == 0) {
            for (0..word_length) |i| {
                const letter: usize = @intCast(values[position + 2 + i] - 97);
                const edge = (node - 1) * ALPHABET_SIZE + letter;
                var child = children[edge];
                if (child == 0) {
                    if (used_nodes == NODE_CAPACITY) return -1;
                    used_nodes += 1;
                    child = used_nodes;
                    children[edge] = child;
                }
                node = child;
            }
            if (!terminal[node - 1]) {
                terminal[node - 1] = true;
                node = 1;
                subtree_words[node - 1] += 1;
                for (0..word_length) |i| {
                    const letter: usize = @intCast(values[position + 2 + i] - 97);
                    node = children[(node - 1) * ALPHABET_SIZE + letter];
                    subtree_words[node - 1] += 1;
                }
                active_hash_sum += word_hash;
                observed = 1;
            }
        } else {
            var traversed: usize = 0;
            while (traversed < word_length and node != 0) : (traversed += 1) {
                const letter: usize = @intCast(values[position + 2 + traversed] - 97);
                node = children[(node - 1) * ALPHABET_SIZE + letter];
            }
            if (traversed != word_length) node = 0;
            if (opcode == 1) {
                if (node != 0 and terminal[node - 1]) {
                    terminal[node - 1] = false;
                    node = 1;
                    subtree_words[node - 1] -= 1;
                    for (0..word_length) |i| {
                        const letter: usize = @intCast(values[position + 2 + i] - 97);
                        node = children[(node - 1) * ALPHABET_SIZE + letter];
                        subtree_words[node - 1] -= 1;
                    }
                    active_hash_sum -= word_hash;
                    observed = 1;
                }
            } else if (opcode == 2) {
                observed = @intFromBool(node != 0 and terminal[node - 1]);
            } else if (opcode == 3) {
                observed = @intFromBool(node != 0 and subtree_words[node - 1] != 0);
            } else if (opcode == 4) {
                observed = if (node == 0) 0 else @intCast(subtree_words[node - 1]);
            } else {
                observed = @intCast(subtree_words[0]);
            }
        }

        checksum += (@as(i64, @intCast(operation)) + 1) * (observed + OFFSET);
        operation += 1;
        position += 2 + word_length;
    }

    checksum += (@as(i64, @intCast(operation)) + 1) * (active_hash_sum + OFFSET);
    return checksum;
}
