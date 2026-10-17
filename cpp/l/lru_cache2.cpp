#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 64
#define MAX_OPERATIONS 256
#define MAP_SIZE 1024
#define MAX_INPUT_LENGTH 771

typedef struct {
    int32_t key;
    int32_t value;
    int previous;
    int next;
} cache_node;

typedef struct {
    int32_t key;
    int node;
    uint8_t state;
} map_entry;

static uint32_t hash_key(int32_t key)
{
    uint32_t value = (uint32_t)key;
    value ^= value >> 16;
    value *= UINT32_C(0x7feb352d);
    value ^= value >> 15;
    value *= UINT32_C(0x846ca68b);
    value ^= value >> 16;
    return value & (MAP_SIZE - 1);
}

static int map_find(const map_entry *map, int32_t key)
{
    uint32_t slot = hash_key(key);
    for (uint32_t probe = 0; probe < MAP_SIZE; ++probe) {
        uint32_t index = (slot + probe) & (MAP_SIZE - 1);
        if (map[index].state == 0) return -1;
        if (map[index].state == 1 && map[index].key == key) return map[index].node;
    }
    return -1;
}

static int map_insert(map_entry *map, int32_t key, int node)
{
    uint32_t slot = hash_key(key);
    int first_tombstone = -1;
    for (uint32_t probe = 0; probe < MAP_SIZE; ++probe) {
        uint32_t index = (slot + probe) & (MAP_SIZE - 1);
        if (map[index].state == 1 && map[index].key == key) return 0;
        if (map[index].state == 2 && first_tombstone == -1) first_tombstone = (int)index;
        if (map[index].state == 0) {
            uint32_t destination = first_tombstone == -1 ? index : (uint32_t)first_tombstone;
            map[destination].key = key;
            map[destination].node = node;
            map[destination].state = 1;
            return 1;
        }
    }
    if (first_tombstone != -1) {
        map[first_tombstone].key = key;
        map[first_tombstone].node = node;
        map[first_tombstone].state = 1;
        return 1;
    }
    return 0;
}

static void map_remove(map_entry *map, int32_t key)
{
    uint32_t slot = hash_key(key);
    for (uint32_t probe = 0; probe < MAP_SIZE; ++probe) {
        uint32_t index = (slot + probe) & (MAP_SIZE - 1);
        if (map[index].state == 0) return;
        if (map[index].state == 1 && map[index].key == key) {
            map[index].state = 2;
            return;
        }
    }
}

static void unlink_node(cache_node *nodes, int *head, int *tail, int node)
{
    int previous = nodes[node].previous;
    int next = nodes[node].next;
    if (previous == -1) *head = next;
    else nodes[previous].next = next;
    if (next == -1) *tail = previous;
    else nodes[next].previous = previous;
}

static void link_at_head(cache_node *nodes, int *head, int *tail, int node)
{
    nodes[node].previous = -1;
    nodes[node].next = *head;
    if (*head == -1) *tail = node;
    else nodes[*head].previous = node;
    *head = node;
}

static void promote_node(cache_node *nodes, int *head, int *tail, int node)
{
    if (*head == node) return;
    unlink_node(nodes, head, tail, node);
    link_at_head(nodes, head, tail, node);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t lru_cache2(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_CAPACITY || input[1] < 0 || input[1] > MAX_OPERATIONS) return -1;
    int cache_capacity = (int)input[0];
    int operation_count = (int)input[1];
    if (length != 2 + (size_t)operation_count * 3) return -1;

    cache_node nodes[MAX_CAPACITY];
    map_entry map[MAP_SIZE] = {0};
    int32_t seen_put_keys[MAX_OPERATIONS];
    int seen_count = 0;
    int head = -1, tail = -1, node_count = 0;
    int64_t results[MAX_OPERATIONS];

    for (int operation = 0; operation < operation_count; ++operation) {
        size_t base = 2 + (size_t)operation * 3;
        int64_t opcode_value = input[base];
        int64_t first = input[base + 1];
        int64_t second = input[base + 2];
        if (opcode_value < 0 || opcode_value > 4) return -1;
        int opcode = (int)opcode_value;
        if (opcode == 0) {
            if (first < INT32_MIN || first > INT32_MAX || second < INT32_MIN || second > INT32_MAX) return -1;
            for (int index = 0; index < seen_count; ++index)
                if (seen_put_keys[index] == (int32_t)first) return -1;
            seen_put_keys[seen_count++] = (int32_t)first;
            int node;
            if (node_count < cache_capacity) node = node_count++;
            else {
                node = tail;
                map_remove(map, nodes[node].key);
                unlink_node(nodes, &head, &tail, node);
            }
            nodes[node].key = (int32_t)first;
            nodes[node].value = (int32_t)second;
            if (!map_insert(map, nodes[node].key, node)) return -1;
            link_at_head(nodes, &head, &tail, node);
            results[operation] = INT64_MIN;
        } else if (opcode == 1) {
            if (first < INT32_MIN || first > INT32_MAX || second != 0) return -1;
            int node = map_find(map, (int32_t)first);
            if (node == -1) return -1;
            promote_node(nodes, &head, &tail, node);
            results[operation] = nodes[node].value;
        } else {
            if (first != 0 || second != 0) return -1;
            if (opcode == 2) results[operation] = node_count;
            else if (opcode == 3) results[operation] = cache_capacity;
            else results[operation] = node_count == 0 ? 1 : 0;
        }
    }

    size_t output_bytes = (size_t)operation_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (int operation = 0; operation < operation_count; ++operation)
        store_i64_le(output, (size_t)operation * 8, results[operation]);
    return (int64_t)output_bytes;
}
