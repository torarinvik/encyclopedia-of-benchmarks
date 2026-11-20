#include <stddef.h>
#include <stdint.h>

#define HB_GENERATIONS 4
#define HB_BUCKETS 8
#define HB_KEYS 32
#define HB_MAX_OPS 64
#define HB_MAX_WORDS (1 + 3 * HB_MAX_OPS + 1)
#define HB_MISS (-2147483647 - 1)

static int hb_find_in_table(const int16_t heads[HB_GENERATIONS][HB_BUCKETS],
                            const int16_t keys[HB_GENERATIONS][HB_KEYS],
                            const int16_t links[HB_GENERATIONS][HB_KEYS],
                            int table, int key) {
    int node = heads[table][key % HB_BUCKETS];
    while (node >= 0) {
        if (keys[table][node] == key) return node;
        node = links[table][node];
    }
    return -1;
}

static int hb_find(const int16_t heads[HB_GENERATIONS][HB_BUCKETS],
                   const int16_t keys[HB_GENERATIONS][HB_KEYS],
                   const int16_t links[HB_GENERATIONS][HB_KEYS],
                   const int newest, int key, int *found_table) {
    for (int age = 0; age < HB_GENERATIONS; ++age) {
        const int table = (newest + age) % HB_GENERATIONS;
        const int node = hb_find_in_table(heads, keys, links, table, key);
        if (node >= 0) {
            *found_table = table;
            return node;
        }
    }
    *found_table = -1;
    return -1;
}

static void hb_put(int16_t heads[HB_GENERATIONS][HB_BUCKETS],
                   int16_t keys[HB_GENERATIONS][HB_KEYS],
                   int16_t values[HB_GENERATIONS][HB_KEYS],
                   int16_t links[HB_GENERATIONS][HB_KEYS],
                   int16_t used[HB_GENERATIONS], int newest,
                   int key, int value) {
    int node = hb_find_in_table(heads, keys, links, newest, key);
    if (node >= 0) {
        values[newest][node] = (int16_t)value;
        return;
    }
    for (node = 0; node < HB_KEYS && keys[newest][node] >= 0; ++node) { }
    if (node >= HB_KEYS) return;
    ++used[newest];
    const int bucket = key % HB_BUCKETS;
    keys[newest][node] = (int16_t)key;
    values[newest][node] = (int16_t)value;
    links[newest][node] = heads[newest][bucket];
    heads[newest][bucket] = (int16_t)node;
}

static void hb_remove(int16_t heads[HB_GENERATIONS][HB_BUCKETS],
                      int16_t keys[HB_GENERATIONS][HB_KEYS],
                      int16_t values[HB_GENERATIONS][HB_KEYS],
                      int16_t links[HB_GENERATIONS][HB_KEYS],
                      int16_t used[HB_GENERATIONS], int table, int key, int target) {
    const int bucket = key % HB_BUCKETS;
    int previous = -1;
    int node = heads[table][bucket];
    while (node >= 0 && node != target) {
        previous = node;
        node = links[table][node];
    }
    if (node < 0) return;
    if (previous < 0) heads[table][bucket] = links[table][node];
    else links[table][previous] = links[table][node];
    keys[table][node] = -1;
    values[table][node] = 0;
    links[table][node] = -1;
    --used[table];
}

static void hb_write_i64_le(uint8_t *output, size_t index, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (int byte = 0; byte < 8; ++byte)
        output[index * 8 + (size_t)byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t hashbelt_aging_hash_table(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > HB_MAX_WORDS) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > HB_MAX_OPS) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + 3 * count) return -1;
    for (size_t op = 0; op < count; ++op) {
        const int64_t opcode = input[1 + 3 * op];
        const int64_t key = input[2 + 3 * op];
        const int64_t argument = input[3 + 3 * op];
        if (opcode == 0) {
            if (key < 0 || key >= HB_KEYS || argument < -1000 || argument > 1000) return -1;
        } else if (opcode == 1) {
            if (key < 0 || key >= HB_KEYS || argument != 0) return -1;
        } else if (opcode == 2) {
            if (key != 0 || argument != 0) return -1;
        } else {
            return -1;
        }
    }

    const size_t required = count * 8;
    if (output == NULL || capacity < required) return -2;

    int16_t heads[HB_GENERATIONS][HB_BUCKETS];
    int16_t keys[HB_GENERATIONS][HB_KEYS];
    int16_t stored_values[HB_GENERATIONS][HB_KEYS] = {{0}};
    int16_t links[HB_GENERATIONS][HB_KEYS] = {{0}};
    int16_t used[HB_GENERATIONS] = {0};
    int64_t trace[HB_MAX_OPS] = {0};
    for (int generation = 0; generation < HB_GENERATIONS; ++generation)
        for (int bucket = 0; bucket < HB_BUCKETS; ++bucket)
            heads[generation][bucket] = -1;
    for (int generation = 0; generation < HB_GENERATIONS; ++generation)
        for (int slot = 0; slot < HB_KEYS; ++slot) keys[generation][slot] = -1;
    int newest = 0;

    for (size_t op = 0; op < count; ++op) {
        const int opcode = (int)input[1 + 3 * op];
        const int key = (int)input[2 + 3 * op];
        const int argument = (int)input[3 + 3 * op];
        if (opcode == 0) {
            int found_table;
            const int node = hb_find(heads, keys, links, newest, key, &found_table);
            trace[op] = found_table < 0 ? 1 : 0;
            if (found_table >= 0 && found_table != newest)
                hb_remove(heads, keys, stored_values, links, used, found_table, key, node);
            hb_put(heads, keys, stored_values, links, used, newest, key, argument);
        } else if (opcode == 1) {
            int found_table;
            const int node = hb_find(heads, keys, links, newest, key, &found_table);
            if (node < 0) {
                trace[op] = HB_MISS;
            } else {
                trace[op] = stored_values[found_table][node];
                if (found_table != newest) {
                    hb_remove(heads, keys, stored_values, links, used, found_table, key, node);
                    hb_put(heads, keys, stored_values, links, used, newest, key, (int)trace[op]);
                }
            }
        } else {
            const int oldest = (newest + HB_GENERATIONS - 1) % HB_GENERATIONS;
            trace[op] = used[oldest];
            for (int bucket = 0; bucket < HB_BUCKETS; ++bucket) heads[oldest][bucket] = -1;
            for (int slot = 0; slot < HB_KEYS; ++slot) keys[oldest][slot] = -1;
            used[oldest] = 0;
            newest = oldest;
        }
    }
    for (size_t op = 0; op < count; ++op) hb_write_i64_le(output, op, trace[op]);
    return (int64_t)required;
}
