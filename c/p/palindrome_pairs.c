#include <stddef.h>
#include <stdint.h>

enum { MAX_WORDS = 8, MAX_WORD_LENGTH = 8, HASH_CAPACITY = 17, MAX_INPUT = 74, MAX_OUTPUT = 56 };

static int is_palindrome(const int words[MAX_WORDS][MAX_WORD_LENGTH], int word_id, int left, int right)
{
    --right;
    while (left < right) {
        if (words[word_id][left] != words[word_id][right]) return 0;
        ++left;
        --right;
    }
    return 1;
}

static int64_t encode_word(const int words[MAX_WORDS][MAX_WORD_LENGTH], int word_id, int left, int right, int reverse)
{
    int64_t key = 1;
    if (reverse) {
        for (int i = right; i > left;) { --i; key = key * 5 + words[word_id][i] + 1; }
    } else {
        for (int i = left; i < right; ++i) key = key * 5 + words[word_id][i] + 1;
    }
    return key;
}

static size_t find_slot(const int64_t keys[HASH_CAPACITY], int64_t key)
{
    size_t slot = (size_t)(key % HASH_CAPACITY);
    while (keys[slot] != 0 && keys[slot] != key) slot = (slot + 1) % HASH_CAPACITY;
    return slot;
}

static void mark_lookup(const int64_t keys[HASH_CAPACITY], const int heads[HASH_CAPACITY],
                        const int next_word[MAX_WORDS], int64_t key, int fixed_id,
                        int fixed_on_right, uint8_t found[MAX_WORDS][MAX_WORDS])
{
    const size_t slot = find_slot(keys, key);
    if (keys[slot] != key) return;
    for (int word_id = heads[slot]; word_id >= 0; word_id = next_word[word_id]) {
        if (word_id == fixed_id) continue;
        if (fixed_on_right) found[word_id][fixed_id] = 1;
        else found[fixed_id][word_id] = 1;
    }
}

int64_t palindrome_pairs(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT || input[0] < 0 || input[0] > MAX_WORDS) return -1;
    const int count = (int)input[0];
    int words[MAX_WORDS][MAX_WORD_LENGTH] = {{0}};
    int word_length[MAX_WORDS] = {0};
    size_t cursor = 1;
    for (int word_id = 0; word_id < count; ++word_id) {
        if (cursor >= length || input[cursor] < 0 || input[cursor] > MAX_WORD_LENGTH) return -1;
        const int size = (int)input[cursor++];
        if (cursor + (size_t)size > length) return -1;
        word_length[word_id] = size;
        for (int i = 0; i < size; ++i) {
            if (input[cursor] < 0 || input[cursor] >= 4) return -1;
            words[word_id][i] = (int)input[cursor++];
        }
    }
    if (cursor != length) return -1;

    int64_t keys[HASH_CAPACITY] = {0};
    int heads[HASH_CAPACITY], tails[HASH_CAPACITY], next_word[MAX_WORDS];
    for (int i = 0; i < HASH_CAPACITY; ++i) heads[i] = tails[i] = -1;
    for (int i = 0; i < MAX_WORDS; ++i) next_word[i] = -1;
    for (int word_id = 0; word_id < count; ++word_id) {
        const int64_t key = encode_word(words, word_id, 0, word_length[word_id], 0);
        const size_t slot = find_slot(keys, key);
        if (keys[slot] == 0) { keys[slot] = key; heads[slot] = word_id; }
        else next_word[tails[slot]] = word_id;
        tails[slot] = word_id;
    }

    uint8_t found[MAX_WORDS][MAX_WORDS] = {{0}};
    for (int word_id = 0; word_id < count; ++word_id) {
        const int size = word_length[word_id];
        for (int split = 0; split <= size; ++split) {
            if (is_palindrome(words, word_id, 0, split)) {
                const int64_t key = encode_word(words, word_id, split, size, 1);
                mark_lookup(keys, heads, next_word, key, word_id, 1, found);
            }
            if (is_palindrome(words, word_id, split, size)) {
                const int64_t key = encode_word(words, word_id, 0, split, 1);
                mark_lookup(keys, heads, next_word, key, word_id, 0, found);
            }
        }
    }

    uint8_t staged[MAX_OUTPUT];
    size_t bytes = 0;
    for (int left = 0; left < count; ++left)
        for (int right = 0; right < count; ++right)
            if (left != right && found[left][right]) staged[bytes++] = (uint8_t)(left * MAX_WORDS + right);
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
