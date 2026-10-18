#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define TABLE_CAPACITY 16
#define MAX_ACTIVE_ENTRIES 14
#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH (1 + 3 * MAX_OPERATIONS)
#define MAX_OUTPUT_BYTES (8 * MAX_OPERATIONS)
#define MAX_PROBE_DISTANCE 64

typedef struct {
    uint32_t key;
    uint32_t value;
    uint32_t psl;
    bool occupied;
} Entry;

typedef struct {
    Entry entries[TABLE_CAPACITY];
    size_t count;
} RobinHoodMap;

static size_t hash_key(uint32_t key) {
    const uint64_t product = (uint64_t)key * UINT64_C(0x9E3779B97F4A7C15);
    return (size_t)((product >> 32) & (TABLE_CAPACITY - 1));
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255);
        bits >>= 8;
    }
}

static bool map_put(RobinHoodMap *map, uint32_t key, uint32_t value) {
    if ((map->count * 100) / TABLE_CAPACITY >= 90) return false;
    Entry entry = {.key = key, .value = value, .psl = 0, .occupied = true};
    size_t index = hash_key(key);
    uint32_t probes = 0;
    while (probes < MAX_PROBE_DISTANCE) {
        Entry *resident = &map->entries[index];
        if (!resident->occupied) {
            *resident = entry;
            ++map->count;
            return true;
        }
        if (resident->key == key) {
            resident->value = value;
            return true;
        }
        if (entry.psl > resident->psl) {
            const Entry temporary = *resident;
            *resident = entry;
            entry = temporary;
        }
        ++entry.psl;
        index = (index + 1) & (TABLE_CAPACITY - 1);
        ++probes;
    }
    return false;
}

static int64_t map_get(const RobinHoodMap *map, uint32_t key) {
    size_t index = hash_key(key);
    uint32_t psl = 0;
    while (psl < MAX_PROBE_DISTANCE) {
        const Entry *resident = &map->entries[index];
        if (!resident->occupied) return -1;
        if (resident->key == key) return (int64_t)resident->value;
        if (psl > resident->psl) return -1;
        index = (index + 1) & (TABLE_CAPACITY - 1);
        ++psl;
    }
    return -1;
}

static void map_backshift(RobinHoodMap *map, size_t start) {
    size_t index = start;
    for (size_t iteration = 0; iteration < TABLE_CAPACITY; ++iteration) {
        const size_t next = (index + 1) & (TABLE_CAPACITY - 1);
        if (!map->entries[next].occupied || map->entries[next].psl == 0) {
            map->entries[index].occupied = false;
            map->entries[index].psl = 0;
            return;
        }
        map->entries[index] = map->entries[next];
        --map->entries[index].psl;
        index = next;
    }
}

static bool map_remove(RobinHoodMap *map, uint32_t key) {
    size_t index = hash_key(key);
    uint32_t psl = 0;
    while (psl < MAX_PROBE_DISTANCE) {
        Entry *resident = &map->entries[index];
        if (!resident->occupied) return false;
        if (resident->key == key) {
            map_backshift(map, index);
            --map->count;
            return true;
        }
        if (psl > resident->psl) return false;
        index = (index + 1) & (TABLE_CAPACITY - 1);
        ++psl;
    }
    return false;
}

static void map_clear(RobinHoodMap *map) {
    for (size_t index = 0; index < TABLE_CAPACITY; ++index) {
        map->entries[index].occupied = false;
        map->entries[index].psl = 0;
    }
    map->count = 0;
}

static uint32_t map_max_psl(const RobinHoodMap *map) {
    uint32_t maximum = 0;
    for (size_t index = 0; index < TABLE_CAPACITY; ++index)
        if (map->entries[index].occupied && map->entries[index].psl > maximum)
            maximum = map->entries[index].psl;
    return maximum;
}

int64_t robin_hood_hash(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[0];
    if (length != 1 + 3 * operation_count) return -1;

    RobinHoodMap map = {0};
    int64_t results[MAX_OPERATIONS] = {0};
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = 1 + 3 * operation;
        const int64_t opcode = input[offset];
        const int64_t raw_key = input[offset + 1];
        const int64_t raw_value = input[offset + 2];
        if (opcode == 0) {
            if (raw_key < 0 || raw_key > UINT32_MAX || raw_value < 100 || raw_value > 1000000) return -1;
            if (!map_put(&map, (uint32_t)raw_key, (uint32_t)raw_value)) return -1;
            if (map.count > MAX_ACTIVE_ENTRIES) return -1;
            results[operation] = -2;
        } else if (opcode == 1 || opcode == 2) {
            if (raw_key < 0 || raw_key > UINT32_MAX || raw_value != 0) return -1;
            const uint32_t key = (uint32_t)raw_key;
            results[operation] = opcode == 1 ? map_get(&map, key) : (map_remove(&map, key) ? 1 : 0);
        } else if (opcode >= 3 && opcode <= 7) {
            if (raw_key != 0 || raw_value != 0) return -1;
            if (opcode == 3) results[operation] = (int64_t)map.count;
            else if (opcode == 4) results[operation] = (int64_t)((map.count * 100) / TABLE_CAPACITY);
            else if (opcode == 5) results[operation] = map_max_psl(&map);
            else if (opcode == 6) { map_clear(&map); results[operation] = -3; }
            else results[operation] = map.count == 0 ? 1 : 0;
        } else return -1;
    }

    const size_t output_bytes = operation_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    for (size_t operation = 0; operation < operation_count; ++operation)
        put_i64_le(staged, operation * 8, results[operation]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
