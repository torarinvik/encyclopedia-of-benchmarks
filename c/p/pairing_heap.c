#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 128
#define MAX_INPUT_LENGTH (MAX_ITEMS + 1)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_LENGTH + 1)
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

typedef struct {
    int32_t key;
    int first_child;
    int next_sibling;
} PairingNode;

static int meld(int first, int second, PairingNode *nodes) {
    if (first < 0) return second;
    if (second < 0) return first;
    if (nodes[second].key < nodes[first].key) {
        const int temporary = first;
        first = second;
        second = temporary;
    }
    nodes[second].next_sibling = nodes[first].first_child;
    nodes[first].first_child = second;
    nodes[first].next_sibling = -1;
    return first;
}

static uint64_t hash_key(uint64_t hash, int32_t key) {
    const uint32_t bits = (uint32_t)key;
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (bits >> (byte * 8)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int64_t pairing_heap(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 2 || raw_count > MAX_ITEMS ||
        length != 1 + (size_t)raw_count) return -1;
    const size_t count = (size_t)raw_count;

    PairingNode nodes[MAX_ITEMS];
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = values[1 + i];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        for (size_t previous = 0; previous < i; ++previous)
            if (values[1 + previous] == value) return -1;
        nodes[i] = (PairingNode){(int32_t)value, -1, -1};
    }

    int root = -1;
    for (size_t i = 0; i < count; ++i) root = meld(root, (int)i, nodes);

    uint64_t hash = FNV_OFFSET_BASIS;
    for (size_t extraction = 0; extraction + 1 < count; ++extraction) {
        const int removed = root;
        hash = hash_key(hash, nodes[removed].key);
        int forest[MAX_ITEMS];
        int paired[MAX_ITEMS];
        size_t forest_count = 0;
        int child = nodes[removed].first_child;
        nodes[removed].first_child = -1;
        while (child >= 0) {
            const int next = nodes[child].next_sibling;
            nodes[child].next_sibling = -1;
            forest[forest_count++] = child;
            child = next;
        }
        size_t paired_count = 0;
        for (size_t i = 0; i < forest_count; i += 2) {
            const int right = i + 1 < forest_count ? forest[i + 1] : -1;
            paired[paired_count++] = meld(forest[i], right, nodes);
        }
        int rebuilt = -1;
        while (paired_count > 0) rebuilt = meld(rebuilt, paired[--paired_count], nodes);
        root = rebuilt;
    }
    return (int64_t)(hash & INT64_MAX);
}
