module trie;

// Fixed-capacity lowercase trie with set semantics and subtree word counts.
fn long trie_benchmark(long* values, usz length) @export("trie_benchmark")
{
    if (length > 1024) return -1;
    ushort[26624] children;
    bool[1024] terminal;
    usz[1024] subtree_words;
    for (usz i = 0; i < 26624; i++) children[i] = 0;
    for (usz i = 0; i < 1024; i++) { terminal[i] = false; subtree_words[i] = 0; }
    usz used_nodes = 1;
    usz position = 0;
    usz operation = 0;
    long checksum = 0;
    long active_hash_sum = 0;

    while (position < length) {
        if (position + 1 >= length) return -1;
        long opcode = values[position];
        long word_length_value = values[position + 1];
        if (opcode < 0 || opcode > 5 || word_length_value < 0 || word_length_value > 128) return -1;
        usz word_length = (usz)word_length_value;
        if (opcode == 5 && word_length != 0) return -1;
        if (word_length > length - position - 2) return -1;

        long word_hash = (long)word_length + 1;
        for (usz i = 0; i < word_length; i++) {
            long character = values[position + 2 + i];
            if (character < 97 || character > 122) return -1;
            word_hash = (word_hash * 31 + character - 96) % 1000000007;
        }

        usz node = 1;
        long observed = 0;
        if (opcode == 0) {
            for (usz i = 0; i < word_length; i++) {
                usz letter = (usz)(values[position + 2 + i] - 97);
                usz edge = (node - 1) * 26 + letter;
                usz child = (usz)children[edge];
                if (child == 0) {
                    if (used_nodes == 1024) return -1;
                    used_nodes++;
                    child = used_nodes;
                    children[edge] = (ushort)child;
                }
                node = child;
            }
            if (!terminal[node - 1]) {
                terminal[node - 1] = true;
                node = 1;
                subtree_words[node - 1]++;
                for (usz i = 0; i < word_length; i++) {
                    usz letter = (usz)(values[position + 2 + i] - 97);
                    node = children[(node - 1) * 26 + letter];
                    subtree_words[node - 1]++;
                }
                active_hash_sum += word_hash;
                observed = 1;
            }
        } else {
            usz traversed = 0;
            while (traversed < word_length && node != 0) {
                usz letter = (usz)(values[position + 2 + traversed] - 97);
                node = children[(node - 1) * 26 + letter];
                traversed++;
            }
            if (traversed != word_length) node = 0;
            if (opcode == 1) {
                if (node != 0 && terminal[node - 1]) {
                    terminal[node - 1] = false;
                    node = 1;
                    subtree_words[node - 1]--;
                    for (usz i = 0; i < word_length; i++) {
                        usz letter = (usz)(values[position + 2 + i] - 97);
                        node = children[(node - 1) * 26 + letter];
                        subtree_words[node - 1]--;
                    }
                    active_hash_sum -= word_hash;
                    observed = 1;
                }
            } else if (opcode == 2) {
                observed = (long)(node != 0 && terminal[node - 1]);
            } else if (opcode == 3) {
                observed = (long)(node != 0 && subtree_words[node - 1] != 0);
            } else if (opcode == 4) {
                observed = node == 0 ? 0 : (long)subtree_words[node - 1];
            } else {
                observed = (long)subtree_words[0];
            }
        }

        checksum += ((long)operation + 1) * (observed + 1000000);
        operation++;
        position += 2 + word_length;
    }

    checksum += ((long)operation + 1) * (active_hash_sum + 1000000);
    return checksum;
}
