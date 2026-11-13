module palindrome_pairs;

const usz MAX_WORDS = 8;
const usz MAX_WORD_LENGTH = 8;
const usz HASH_CAPACITY = 17;
const usz MAX_INPUT = 74;

fn bool pp_palindrome(int[MAX_WORDS][MAX_WORD_LENGTH]* words, int word_id, int left, int right) {
    right -= 1;
    while (left < right) {
        if ((*words)[word_id][left] != (*words)[word_id][right]) return false;
        left += 1;
        right -= 1;
    }
    return true;
}

fn long pp_encode(int[MAX_WORDS][MAX_WORD_LENGTH]* words, int word_id, int left, int right, bool reverse) {
    long key = 1;
    if (reverse) {
        int i = right;
        while (i > left) { i -= 1; key = key * 5 + (*words)[word_id][i] + 1; }
    } else {
        for (int i = left; i < right; i += 1) key = key * 5 + (*words)[word_id][i] + 1;
    }
    return key;
}

fn usz pp_slot(long[HASH_CAPACITY]* keys, long key) {
    usz slot = (usz)(key % (long)HASH_CAPACITY);
    while ((*keys)[slot] != 0 && (*keys)[slot] != key) slot = (slot + 1) % HASH_CAPACITY;
    return slot;
}

fn void pp_mark(long[HASH_CAPACITY]* keys, int[HASH_CAPACITY]* heads, int[MAX_WORDS]* next_word,
                long key, int fixed_id, bool fixed_on_right, bool[MAX_WORDS][MAX_WORDS]* found) {
    usz slot = pp_slot(keys, key);
    if ((*keys)[slot] != key) return;
    int word_id = (*heads)[slot];
    while (word_id >= 0) {
        if (word_id != fixed_id) {
            if (fixed_on_right) (*found)[word_id][fixed_id] = true;
            else (*found)[fixed_id][word_id] = true;
        }
        word_id = (*next_word)[word_id];
    }
}

fn long palindrome_pairs(long* input, usz length, char* output, usz capacity) @export("palindrome_pairs") {
    if (input == null || length < 1 || length > MAX_INPUT || input[0] < 0 || input[0] > (long)MAX_WORDS) return -1;
    int count = (int)input[0];
    int[MAX_WORDS][MAX_WORD_LENGTH] words = {};
    int[MAX_WORDS] word_length = {};
    usz cursor = 1;
    for (int word_id = 0; word_id < count; word_id += 1) {
        if (cursor >= length || input[cursor] < 0 || input[cursor] > (long)MAX_WORD_LENGTH) return -1;
        int size = (int)input[cursor]; cursor += 1;
        if (cursor + (usz)size > length) return -1;
        word_length[word_id] = size;
        for (int i = 0; i < size; i += 1) {
            if (input[cursor] < 0 || input[cursor] >= 4) return -1;
            words[word_id][i] = (int)input[cursor]; cursor += 1;
        }
    }
    if (cursor != length) return -1;

    long[HASH_CAPACITY] keys = {};
    int[HASH_CAPACITY] heads = {};
    for (usz i = 0; i < HASH_CAPACITY; i += 1) heads[i] = -1;
    int[MAX_WORDS] next_word = {};
    for (usz i = 0; i < MAX_WORDS; i += 1) next_word[i] = -1;
    for (int word_id = 0; word_id < count; word_id += 1) {
        long key = pp_encode(&words, word_id, 0, word_length[word_id], false);
        usz slot = pp_slot(&keys, key);
        if (keys[slot] == 0) { keys[slot] = key; heads[slot] = word_id; }
        else { next_word[word_id] = heads[slot]; heads[slot] = word_id; }
    }

    bool[MAX_WORDS][MAX_WORDS] found = {};
    for (int word_id = 0; word_id < count; word_id += 1) {
        int size = word_length[word_id];
        for (int split = 0; split <= size; split += 1) {
            if (pp_palindrome(&words, word_id, 0, split)) pp_mark(&keys, &heads, &next_word, pp_encode(&words, word_id, split, size, true), word_id, true, &found);
            if (pp_palindrome(&words, word_id, split, size)) pp_mark(&keys, &heads, &next_word, pp_encode(&words, word_id, 0, split, true), word_id, false, &found);
        }
    }
    char[MAX_WORDS * (MAX_WORDS - 1)] staged = {};
    usz bytes = 0;
    for (int left = 0; left < count; left += 1)
        for (int right = 0; right < count; right += 1)
            if (left != right && found[left][right]) { staged[bytes] = (char)(left * MAX_WORDS + right); bytes += 1; }
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < bytes; i += 1) output[i] = staged[i];
    return (long)bytes;
}
