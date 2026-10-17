#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_word_length = 32;
constexpr std::size_t max_distinct_words = 32;
constexpr std::size_t max_node_index = 1 + max_word_length * max_distinct_words;
constexpr std::size_t node_array_length = max_node_index + 1;
constexpr std::size_t max_valid_input_length = 1 + max_operations * (2 + max_word_length);
constexpr std::size_t max_parseable_input_length = max_valid_input_length + 1;
constexpr std::uint16_t root_index = 1;
constexpr std::uint64_t fnv_offset = UINT64_C(14695981039346656037);
constexpr std::uint64_t fnv_prime = UINT64_C(1099511628211);

struct TrieNode {
    std::array<std::uint16_t, 26> children{};
    std::uint32_t frequency = 0;
    bool terminal = false;
};

struct Suggestion {
    std::uint32_t frequency = 0;
    std::uint8_t length = 0;
    std::array<std::uint8_t, max_word_length> word{};
};

int letter_index(std::int64_t code, std::uint8_t &lowercase)
{
    if (code >= 65 && code <= 90) {
        lowercase = static_cast<std::uint8_t>(code + 32);
        return static_cast<int>(code - 65);
    }
    if (code >= 97 && code <= 122) {
        lowercase = static_cast<std::uint8_t>(code);
        return static_cast<int>(code - 97);
    }
    return -1;
}

void hash_byte(std::uint64_t &hash, std::uint8_t byte) { hash = (hash ^ byte) * fnv_prime; }

void hash_u16(std::uint64_t &hash, std::uint16_t value)
{
    for (unsigned byte = 0; byte < 2; ++byte) hash_byte(hash, static_cast<std::uint8_t>(value >> (8 * byte)));
}

void hash_u32(std::uint64_t &hash, std::uint32_t value)
{
    for (unsigned byte = 0; byte < 4; ++byte) hash_byte(hash, static_cast<std::uint8_t>(value >> (8 * byte)));
}

void hash_string(std::uint64_t &hash, const std::uint8_t *word, std::size_t length)
{
    hash_byte(hash, static_cast<std::uint8_t>(length));
    for (std::size_t index = 0; index < length; ++index) hash_byte(hash, word[index]);
}

std::size_t count_descendants(const TrieNode *nodes, std::uint16_t node)
{
    std::size_t count = 0;
    for (std::size_t letter = 0; letter < 26; ++letter) {
        const std::uint16_t child = nodes[node].children[letter];
        if (child != 0) {
            if (nodes[child].terminal) ++count;
            count += count_descendants(nodes, child);
        }
    }
    return count;
}

void hash_descendants(const TrieNode *nodes, std::uint16_t node,
                      std::array<std::uint8_t, max_word_length> &path,
                      std::size_t path_length, std::uint64_t &hash)
{
    for (std::size_t letter = 0; letter < 26; ++letter) {
        const std::uint16_t child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = static_cast<std::uint8_t>('a' + letter);
            if (nodes[child].terminal) hash_string(hash, path.data(), path_length + 1);
            hash_descendants(nodes, child, path, path_length + 1, hash);
        }
    }
}

int compare_suggestions(const Suggestion &left, const Suggestion &right)
{
    if (left.frequency > right.frequency) return 1;
    if (left.frequency < right.frequency) return -1;
    const std::size_t common = left.length < right.length ? left.length : right.length;
    for (std::size_t index = 0; index < common; ++index) {
        if (left.word[index] > right.word[index]) return 1;
        if (left.word[index] < right.word[index]) return -1;
    }
    if (left.length > right.length) return 1;
    if (left.length < right.length) return -1;
    return 0;
}

void offer_suggestion(std::array<Suggestion, 3> &top, std::size_t &count,
                      std::uint32_t frequency, const std::uint8_t *word, std::size_t length)
{
    Suggestion candidate{};
    candidate.frequency = frequency;
    candidate.length = static_cast<std::uint8_t>(length);
    for (std::size_t index = 0; index < length; ++index) candidate.word[index] = word[index];
    std::size_t position = 0;
    while (position < count && compare_suggestions(candidate, top[position]) <= 0) ++position;
    if (position >= 3) return;
    if (count < 3) ++count;
    for (std::size_t index = count - 1; index > position; --index) top[index] = top[index - 1];
    top[position] = candidate;
}

void collect_top_descendants(const TrieNode *nodes, std::uint16_t node,
                             std::array<std::uint8_t, max_word_length> &path,
                             std::size_t path_length, std::array<Suggestion, 3> &top,
                             std::size_t &count)
{
    for (std::size_t letter = 0; letter < 26; ++letter) {
        const std::uint16_t child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = static_cast<std::uint8_t>('a' + letter);
            const std::size_t word_length = path_length + 1;
            if (nodes[child].terminal)
                offer_suggestion(top, count, nodes[child].frequency, path.data(), word_length);
            collect_top_descendants(nodes, child, path, word_length, top, count);
        }
    }
}

void hash_final_words(const TrieNode *nodes, std::uint16_t node,
                      std::array<std::uint8_t, max_word_length> &path,
                      std::size_t path_length, std::uint64_t &hash)
{
    for (std::size_t letter = 0; letter < 26; ++letter) {
        const std::uint16_t child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = static_cast<std::uint8_t>('a' + letter);
            const std::size_t word_length = path_length + 1;
            if (nodes[child].terminal) {
                hash_string(hash, path.data(), word_length);
                hash_u32(hash, nodes[child].frequency);
            }
            hash_final_words(nodes, child, path, word_length, hash);
        }
    }
}
}

extern "C" std::int64_t trie_multiple_search(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(input[0]);

    std::array<TrieNode, node_array_length> nodes{};
    std::uint16_t next_node = root_index + 1;
    std::size_t word_count = 0;
    std::size_t offset = 1;
    std::uint64_t hash = fnv_offset;
    hash_u16(hash, static_cast<std::uint16_t>(operation_count));

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (offset + 2 > length) return -1;
        const std::int64_t opcode_value = input[offset];
        const std::int64_t word_length_value = input[offset + 1];
        offset += 2;
        if (opcode_value < 0 || opcode_value > 3 || word_length_value < 0 ||
            word_length_value > static_cast<std::int64_t>(max_word_length)) return -1;
        const auto opcode = static_cast<std::uint8_t>(opcode_value);
        const std::size_t word_length = static_cast<std::size_t>(word_length_value);
        if (opcode == 0 && word_length == 0) return -1;
        if (offset + word_length > length) return -1;

        std::array<std::uint8_t, max_word_length> raw_word{};
        std::array<std::uint8_t, max_word_length> folded_word{};
        for (std::size_t index = 0; index < word_length; ++index) {
            if (letter_index(input[offset + index], folded_word[index]) < 0) return -1;
            raw_word[index] = static_cast<std::uint8_t>(input[offset + index]);
        }
        offset += word_length;
        hash_byte(hash, opcode);

        std::uint16_t node = root_index;
        std::size_t matched_length = 0;
        while (matched_length < word_length) {
            const std::size_t letter = static_cast<std::size_t>(folded_word[matched_length] - 'a');
            const std::uint16_t child = nodes[node].children[letter];
            if (child == 0) break;
            node = child;
            ++matched_length;
        }
        const bool full_path = matched_length == word_length;
        const bool exact_match = full_path && nodes[node].terminal;

        if (opcode == 0) {
            if (!exact_match) {
                if (word_count >= max_distinct_words) return -1;
                while (matched_length < word_length) {
                    const std::size_t letter = static_cast<std::size_t>(folded_word[matched_length] - 'a');
                    if (next_node > max_node_index) return -1;
                    const std::uint16_t child = next_node++;
                    nodes[node].children[letter] = child;
                    node = child;
                    ++matched_length;
                }
                nodes[node].terminal = true;
                ++word_count;
            }
        } else if (opcode == 1) {
            const std::uint8_t present = exact_match ? 1 : 0;
            if (exact_match) ++nodes[node].frequency;
            hash_byte(hash, present);
        } else {
            if (exact_match) ++nodes[node].frequency;
            std::size_t descendant_count = 0;
            std::array<Suggestion, 3> top{};
            std::size_t top_count = 0;
            std::array<std::uint8_t, max_word_length> path{};
            for (std::size_t index = 0; index < matched_length; ++index) path[index] = folded_word[index];
            if (opcode == 2) descendant_count = count_descendants(nodes.data(), node);
            else {
                collect_top_descendants(nodes.data(), node, path, matched_length, top, top_count);
                descendant_count = top_count;
            }
            hash_u16(hash, static_cast<std::uint16_t>(descendant_count + (exact_match ? 1 : 0)));
            if (exact_match) hash_string(hash, raw_word.data(), word_length);
            if (opcode == 2) hash_descendants(nodes.data(), node, path, matched_length, hash);
            else for (std::size_t index = 0; index < top_count; ++index)
                hash_string(hash, top[index].word.data(), top[index].length);
        }
    }

    if (offset != length) return -1;
    hash_u16(hash, static_cast<std::uint16_t>(word_count));
    std::array<std::uint8_t, max_word_length> path{};
    hash_final_words(nodes.data(), root_index, path, 0, hash);
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
