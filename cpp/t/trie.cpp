/* Fixed-capacity lowercase trie with set semantics and subtree word counts. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;
constexpr std::size_t max_word_length = 128;
constexpr std::size_t node_capacity = 1024;
constexpr std::size_t alphabet_size = 26;
constexpr std::int64_t hash_mod = 1000000007;
constexpr std::int64_t offset = 1000000;
}

extern "C" std::int64_t trie_benchmark(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > max_values) return -1;
    std::size_t children[node_capacity * alphabet_size]{};
    bool terminal[node_capacity]{};
    std::size_t subtree_words[node_capacity]{};
    std::size_t used_nodes = 1, position = 0, operation = 0;
    std::int64_t checksum = 0, active_hash_sum = 0;

    while (position < length) {
        if (position + 1 >= length) return -1;
        const std::int64_t opcode = values[position];
        const std::int64_t word_length_value = values[position + 1];
        if (opcode < 0 || opcode > 5 || word_length_value < 0 ||
            word_length_value > static_cast<std::int64_t>(max_word_length)) return -1;
        const auto word_length = static_cast<std::size_t>(word_length_value);
        if (opcode == 5 && word_length != 0) return -1;
        if (word_length > length - position - 2) return -1;

        std::int64_t word_hash = static_cast<std::int64_t>(word_length) + 1;
        for (std::size_t i = 0; i < word_length; ++i) {
            const auto character = values[position + 2 + i];
            if (character < 97 || character > 122) return -1;
            word_hash = (word_hash * 31 + (character - 96)) % hash_mod;
        }

        std::size_t node = 1;
        std::int64_t observed = 0;
        if (opcode == 0) {
            for (std::size_t i = 0; i < word_length; ++i) {
                const auto letter = static_cast<std::size_t>(values[position + 2 + i] - 97);
                const auto edge = (node - 1) * alphabet_size + letter;
                auto child = children[edge];
                if (child == 0) {
                    if (used_nodes == node_capacity) return -1;
                    child = ++used_nodes;
                    children[edge] = child;
                }
                node = child;
            }
            if (!terminal[node - 1]) {
                terminal[node - 1] = true;
                node = 1;
                ++subtree_words[node - 1];
                for (std::size_t i = 0; i < word_length; ++i) {
                    const auto letter = static_cast<std::size_t>(values[position + 2 + i] - 97);
                    node = children[(node - 1) * alphabet_size + letter];
                    ++subtree_words[node - 1];
                }
                active_hash_sum += word_hash;
                observed = 1;
            }
        } else {
            std::size_t traversed = 0;
            while (traversed < word_length && node != 0) {
                const auto letter = static_cast<std::size_t>(values[position + 2 + traversed] - 97);
                node = children[(node - 1) * alphabet_size + letter];
                ++traversed;
            }
            if (traversed != word_length) node = 0;
            if (opcode == 1) {
                if (node != 0 && terminal[node - 1]) {
                    terminal[node - 1] = false;
                    node = 1;
                    --subtree_words[node - 1];
                    for (std::size_t i = 0; i < word_length; ++i) {
                        const auto letter = static_cast<std::size_t>(values[position + 2 + i] - 97);
                        node = children[(node - 1) * alphabet_size + letter];
                        --subtree_words[node - 1];
                    }
                    active_hash_sum -= word_hash;
                    observed = 1;
                }
            } else if (opcode == 2) {
                observed = node != 0 && terminal[node - 1];
            } else if (opcode == 3) {
                observed = node != 0 && subtree_words[node - 1] != 0;
            } else if (opcode == 4) {
                observed = node == 0 ? 0 : static_cast<std::int64_t>(subtree_words[node - 1]);
            } else {
                observed = static_cast<std::int64_t>(subtree_words[0]);
            }
        }

        checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + offset);
        ++operation;
        position += 2 + word_length;
    }

    checksum += (static_cast<std::int64_t>(operation) + 1) * (active_hash_sum + offset);
    return checksum;
}
