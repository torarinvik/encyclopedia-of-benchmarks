/* Fixed-capacity lowercase trie with set semantics and subtree word counts. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024
#define MAX_WORD_LENGTH 128
#define NODE_CAPACITY 1024
#define ALPHABET_SIZE 26
#define HASH_MOD INT64_C(1000000007)
#define OFFSET INT64_C(1000000)

int64_t trie_benchmark(const int64_t *values, size_t length)
{
    if (length > MAX_VALUES) return -1;

    size_t children[NODE_CAPACITY * ALPHABET_SIZE] = {0};
    uint8_t terminal[NODE_CAPACITY] = {0};
    size_t subtree_words[NODE_CAPACITY] = {0};
    size_t used_nodes = 1; /* node IDs are one-based; zero means no child */
    size_t position = 0, operation = 0;
    int64_t checksum = 0, active_hash_sum = 0;

    while (position < length) {
        if (position + 1 >= length) return -1;
        const int64_t opcode = values[position];
        const int64_t word_length_value = values[position + 1];
        if (opcode < 0 || opcode > 5 || word_length_value < 0 ||
            word_length_value > MAX_WORD_LENGTH) return -1;
        const size_t word_length = (size_t)word_length_value;
        if (opcode == 5 && word_length != 0) return -1;
        if (word_length > length - position - 2) return -1;

        int64_t word_hash = (int64_t)word_length + 1;
        for (size_t i = 0; i < word_length; ++i) {
            const int64_t character = values[position + 2 + i];
            if (character < 97 || character > 122) return -1;
            word_hash = (word_hash * 31 + (character - 96)) % HASH_MOD;
        }

        size_t node = 1;
        int64_t observed = 0;
        if (opcode == 0) {
            for (size_t i = 0; i < word_length; ++i) {
                const size_t letter = (size_t)(values[position + 2 + i] - 97);
                const size_t edge = (node - 1) * ALPHABET_SIZE + letter;
                size_t child = children[edge];
                if (child == 0) {
                    if (used_nodes == NODE_CAPACITY) return -1;
                    child = ++used_nodes;
                    children[edge] = child;
                }
                node = child;
            }
            if (!terminal[node - 1]) {
                terminal[node - 1] = 1;
                node = 1;
                ++subtree_words[node - 1];
                for (size_t i = 0; i < word_length; ++i) {
                    const size_t letter = (size_t)(values[position + 2 + i] - 97);
                    node = children[(node - 1) * ALPHABET_SIZE + letter];
                    ++subtree_words[node - 1];
                }
                active_hash_sum += word_hash;
                observed = 1;
            }
        } else {
            size_t traversed = 0;
            while (traversed < word_length && node != 0) {
                const size_t letter = (size_t)(values[position + 2 + traversed] - 97);
                node = children[(node - 1) * ALPHABET_SIZE + letter];
                ++traversed;
            }
            if (traversed != word_length) node = 0;
            if (opcode == 1) {
                if (node != 0 && terminal[node - 1]) {
                    terminal[node - 1] = 0;
                    node = 1;
                    --subtree_words[node - 1];
                    for (size_t i = 0; i < word_length; ++i) {
                        const size_t letter = (size_t)(values[position + 2 + i] - 97);
                        node = children[(node - 1) * ALPHABET_SIZE + letter];
                        --subtree_words[node - 1];
                    }
                    active_hash_sum -= word_hash;
                    observed = 1;
                }
            } else if (opcode == 2) {
                observed = (node != 0 && terminal[node - 1]);
            } else if (opcode == 3) {
                observed = (node != 0 && subtree_words[node - 1] != 0);
            } else if (opcode == 4) {
                observed = node == 0 ? 0 : (int64_t)subtree_words[node - 1];
            } else { /* opcode 5: total word count */
                observed = (int64_t)subtree_words[0];
            }
        }

        checksum += ((int64_t)operation + 1) * (observed + OFFSET);
        ++operation;
        position += 2 + word_length;
    }

    checksum += ((int64_t)operation + 1) * (active_hash_sum + OFFSET);
    return checksum;
}
