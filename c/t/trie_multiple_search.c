#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64u
#define MAX_WORD_LENGTH 32u
#define MAX_DISTINCT_WORDS 32u
#define MAX_NODE_INDEX (1u + MAX_WORD_LENGTH * MAX_DISTINCT_WORDS)
#define NODE_ARRAY_LENGTH (MAX_NODE_INDEX + 1u)
#define MAX_VALID_INPUT_LENGTH (1u + MAX_OPERATIONS * (2u + MAX_WORD_LENGTH))
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1u)
#define ROOT_INDEX 1u
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

typedef struct {
    uint16_t children[26];
    uint32_t frequency;
    uint8_t terminal;
} TrieNode;

typedef struct {
    uint32_t frequency;
    uint8_t length;
    uint8_t word[MAX_WORD_LENGTH];
} Suggestion;

static int letter_index(int64_t code, uint8_t *lowercase)
{
    if (code >= 65 && code <= 90) {
        *lowercase = (uint8_t)(code + 32);
        return (int)(code - 65);
    }
    if (code >= 97 && code <= 122) {
        *lowercase = (uint8_t)code;
        return (int)(code - 97);
    }
    return -1;
}

static void hash_byte(uint64_t *hash, uint8_t byte)
{
    *hash = (*hash ^ byte) * FNV_PRIME;
}

static void hash_u16(uint64_t *hash, uint16_t value)
{
    for (unsigned byte = 0; byte < 2u; ++byte)
        hash_byte(hash, (uint8_t)(value >> (8u * byte)));
}

static void hash_u32(uint64_t *hash, uint32_t value)
{
    for (unsigned byte = 0; byte < 4u; ++byte)
        hash_byte(hash, (uint8_t)(value >> (8u * byte)));
}

static void hash_string(uint64_t *hash, const uint8_t *word, size_t length)
{
    hash_byte(hash, (uint8_t)length);
    for (size_t index = 0; index < length; ++index) hash_byte(hash, word[index]);
}

static size_t count_descendants(const TrieNode *nodes, uint16_t node)
{
    size_t count = 0;
    for (size_t letter = 0; letter < 26u; ++letter) {
        const uint16_t child = nodes[node].children[letter];
        if (child != 0) {
            if (nodes[child].terminal) ++count;
            count += count_descendants(nodes, child);
        }
    }
    return count;
}

static void hash_descendants(const TrieNode *nodes, uint16_t node, uint8_t *path,
                             size_t path_length, uint64_t *hash)
{
    for (size_t letter = 0; letter < 26u; ++letter) {
        const uint16_t child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = (uint8_t)('a' + letter);
            if (nodes[child].terminal) hash_string(hash, path, path_length + 1u);
            hash_descendants(nodes, child, path, path_length + 1u, hash);
        }
    }
}

static int compare_suggestions(const Suggestion *left, const Suggestion *right)
{
    if (left->frequency > right->frequency) return 1;
    if (left->frequency < right->frequency) return -1;
    const size_t common = left->length < right->length ? left->length : right->length;
    for (size_t index = 0; index < common; ++index) {
        if (left->word[index] > right->word[index]) return 1;
        if (left->word[index] < right->word[index]) return -1;
    }
    if (left->length > right->length) return 1;
    if (left->length < right->length) return -1;
    return 0;
}

static void offer_suggestion(Suggestion top[3], size_t *count,
                             uint32_t frequency, const uint8_t *word, size_t length)
{
    Suggestion candidate = {0};
    candidate.frequency = frequency;
    candidate.length = (uint8_t)length;
    for (size_t index = 0; index < length; ++index) candidate.word[index] = word[index];

    size_t position = 0;
    while (position < *count && compare_suggestions(&candidate, &top[position]) <= 0) ++position;
    if (position >= 3u) return;
    if (*count < 3u) ++*count;
    for (size_t index = *count - 1u; index > position; --index) top[index] = top[index - 1u];
    top[position] = candidate;
}

static void collect_top_descendants(const TrieNode *nodes, uint16_t node, uint8_t *path,
                                    size_t path_length, Suggestion top[3], size_t *count)
{
    for (size_t letter = 0; letter < 26u; ++letter) {
        const uint16_t child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = (uint8_t)('a' + letter);
            const size_t word_length = path_length + 1u;
            if (nodes[child].terminal)
                offer_suggestion(top, count, nodes[child].frequency, path, word_length);
            collect_top_descendants(nodes, child, path, word_length, top, count);
        }
    }
}

static void hash_final_words(const TrieNode *nodes, uint16_t node, uint8_t *path,
                             size_t path_length, uint64_t *hash)
{
    for (size_t letter = 0; letter < 26u; ++letter) {
        const uint16_t child = nodes[node].children[letter];
        if (child != 0) {
            path[path_length] = (uint8_t)('a' + letter);
            const size_t word_length = path_length + 1u;
            if (nodes[child].terminal) {
                hash_string(hash, path, word_length);
                hash_u32(hash, nodes[child].frequency);
            }
            hash_final_words(nodes, child, path, word_length, hash);
        }
    }
}

int64_t trie_multiple_search(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1u || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[0];

    TrieNode nodes[NODE_ARRAY_LENGTH] = {0};
    uint16_t next_node = ROOT_INDEX + 1u;
    size_t word_count = 0;
    size_t offset = 1u;
    uint64_t hash = FNV_OFFSET;
    hash_u16(&hash, (uint16_t)operation_count);

    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (offset + 2u > length) return -1;
        const int64_t opcode_value = input[offset];
        const int64_t word_length_value = input[offset + 1u];
        offset += 2u;
        if (opcode_value < 0 || opcode_value > 3 || word_length_value < 0 ||
            word_length_value > (int64_t)MAX_WORD_LENGTH) return -1;
        const uint8_t opcode = (uint8_t)opcode_value;
        const size_t word_length = (size_t)word_length_value;
        if (opcode == 0u && word_length == 0u) return -1;
        if (offset + word_length > length) return -1;

        uint8_t raw_word[MAX_WORD_LENGTH];
        uint8_t folded_word[MAX_WORD_LENGTH];
        for (size_t index = 0; index < word_length; ++index) {
            const int letter = letter_index(input[offset + index], &folded_word[index]);
            if (letter < 0) return -1;
            raw_word[index] = (uint8_t)input[offset + index];
        }
        offset += word_length;
        hash_byte(&hash, opcode);

        uint16_t node = ROOT_INDEX;
        size_t matched_length = 0;
        while (matched_length < word_length) {
            const size_t letter = (size_t)(folded_word[matched_length] - 'a');
            const uint16_t child = nodes[node].children[letter];
            if (child == 0) break;
            node = child;
            ++matched_length;
        }
        const int full_path = matched_length == word_length;
        const int exact_match = full_path && nodes[node].terminal;

        if (opcode == 0u) {
            if (!exact_match) {
                if (word_count >= MAX_DISTINCT_WORDS) return -1;
                while (matched_length < word_length) {
                    const size_t letter = (size_t)(folded_word[matched_length] - 'a');
                    if (next_node > MAX_NODE_INDEX) return -1;
                    const uint16_t child = next_node++;
                    nodes[node].children[letter] = child;
                    node = child;
                    ++matched_length;
                }
                nodes[node].terminal = 1u;
                ++word_count;
            }
        } else if (opcode == 1u) {
            const uint8_t present = (uint8_t)(exact_match ? 1u : 0u);
            if (exact_match) ++nodes[node].frequency;
            hash_byte(&hash, present);
        } else {
            if (exact_match) ++nodes[node].frequency;
            size_t descendant_count = 0;
            Suggestion top[3] = {0};
            size_t top_count = 0;
            uint8_t path[MAX_WORD_LENGTH];
            for (size_t index = 0; index < matched_length; ++index) path[index] = folded_word[index];
            if (opcode == 2u) {
                descendant_count = count_descendants(nodes, node);
            } else {
                collect_top_descendants(nodes, node, path, matched_length, top, &top_count);
                descendant_count = top_count;
            }
            const size_t result_count = descendant_count + (exact_match ? 1u : 0u);
            hash_u16(&hash, (uint16_t)result_count);
            if (exact_match) hash_string(&hash, raw_word, word_length);
            if (opcode == 2u) {
                hash_descendants(nodes, node, path, matched_length, &hash);
            } else {
                for (size_t index = 0; index < top_count; ++index)
                    hash_string(&hash, top[index].word, top[index].length);
            }
        }
    }

    if (offset != length) return -1;
    hash_u16(&hash, (uint16_t)word_count);
    uint8_t path[MAX_WORD_LENGTH];
    hash_final_words(nodes, ROOT_INDEX, path, 0u, &hash);
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
