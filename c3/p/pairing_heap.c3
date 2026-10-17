module pairing_heap;

const usz MAX_ITEMS = 128;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_ITEMS + 2;
const ulong FNV_OFFSET_BASIS = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;

fn int meld(int first, int second, long* keys, int* first_child, int* next_sibling) {
    if (first < 0) return second;
    if (second < 0) return first;
    if (keys[second] < keys[first]) {
        int temporary = first;
        first = second;
        second = temporary;
    }
    next_sibling[second] = first_child[first];
    first_child[first] = second;
    next_sibling[first] = -1;
    return first;
}

fn ulong hash_key(ulong hash, int key) {
    uint bits = (uint)key;
    for (uint byte = 0; byte < 4; byte += 1)
        hash = (hash ^ (ulong)((bits >> (byte * 8)) & 255)) * FNV_PRIME;
    return hash;
}

fn long pairing_heap(long* values, usz length) @export("pairing_heap") {
    if (values == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long raw_count = values[0];
    if (raw_count < 2 || raw_count > (long)MAX_ITEMS ||
        length != 1 + (usz)raw_count) return -1;
    usz count = (usz)raw_count;

    long[MAX_ITEMS] keys;
    int[MAX_ITEMS] first_child;
    int[MAX_ITEMS] next_sibling;
    for (usz i = 0; i < count; i += 1) {
        long value = values[1 + i];
        if (value < -2147483648 || value > 2147483647) return -1;
        for (usz previous = 0; previous < i; previous += 1)
            if (values[1 + previous] == value) return -1;
        keys[i] = value;
        first_child[i] = -1;
        next_sibling[i] = -1;
    }

    int root = -1;
    for (usz i = 0; i < count; i += 1)
        root = meld(root, (int)i, &keys[0], &first_child[0], &next_sibling[0]);

    ulong hash = FNV_OFFSET_BASIS;
    for (usz extraction = 0; extraction + 1 < count; extraction += 1) {
        int removed = root;
        hash = hash_key(hash, (int)keys[removed]);
        int[MAX_ITEMS] forest;
        int[MAX_ITEMS] paired;
        usz forest_count = 0;
        int child = first_child[removed];
        first_child[removed] = -1;
        while (child >= 0) {
            int next = next_sibling[child];
            next_sibling[child] = -1;
            forest[forest_count] = child;
            forest_count += 1;
            child = next;
        }
        usz paired_count = 0;
        for (usz i = 0; i < forest_count; i += 2) {
            int right = i + 1 < forest_count ? forest[i + 1] : -1;
            paired[paired_count] = meld(forest[i], right, &keys[0], &first_child[0], &next_sibling[0]);
            paired_count += 1;
        }
        int rebuilt = -1;
        while (paired_count > 0) {
            paired_count -= 1;
            rebuilt = meld(rebuilt, paired[paired_count], &keys[0], &first_child[0], &next_sibling[0]);
        }
        root = rebuilt;
    }
    return (long)(hash & 0x7fffffffffffffff);
}
