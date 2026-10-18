#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_OPERATIONS = 24,
    MAX_INITIAL_CAPACITY = 8,
    MAX_TABLE_CAPACITY = 64,
    MAX_INPUT_LENGTH = 51,
    MAX_OUTPUT_ELEMENTS = 3 + (MAX_OPERATIONS - MAX_TABLE_CAPACITY / 4) + MAX_TABLE_CAPACITY,
    MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
};

enum {
    OP_INSERT = 0,
    OP_REMOVE = 1,
    OP_FIND = 2
};

typedef struct {
    int slots[MAX_TABLE_CAPACITY];
    size_t capacity;
    size_t size;
} Table;

static long probe_insert(const Table *table, int key)
{
    const size_t limit = table->capacity * 100u;
    for (size_t probe = 0u; probe < limit; ++probe) {
        /* The benchmark normatively defines hash(key)=key. The bounded i*i is exact
         * and matches round(pow(i, 2)).
         */
        const size_t index = ((size_t)key + probe * probe) % table->capacity;
        if (table->slots[index] == 0 || table->slots[index] == -1)
            return (long)index;
    }
    return -1;
}

static long probe_find(const Table *table, int key)
{
    const size_t limit = table->capacity * 100u;
    for (size_t probe = 0u; probe < limit; ++probe) {
        const size_t index = ((size_t)key + probe * probe) % table->capacity;
        const int slot = table->slots[index];
        if (slot == 0) return -1;
        if (slot == key) return (long)index;
    }
    return -1;
}

static int insert_key(Table *table, int key);

static int rehash(Table *table)
{
    const size_t old_capacity = table->capacity;
    if (old_capacity > MAX_TABLE_CAPACITY / 2u) return 0;

    int old_slots[MAX_TABLE_CAPACITY] = {0};
    for (size_t index = 0u; index < old_capacity; ++index)
        old_slots[index] = table->slots[index];

    const size_t new_capacity = old_capacity * 2u;
    for (size_t index = 0u; index < new_capacity; ++index) table->slots[index] = 0;
    table->capacity = new_capacity;

    /* The source calls add() for each old key. That same path checks load and
     * can rehash again (notably for the initial-capacity-one case).
     */
    for (size_t index = 0u; index < old_capacity; ++index) {
        const int key = old_slots[index];
        if (key == 0 || key == -1) continue;
        if (table->size == 0u) return 0;
        --table->size;
        if (!insert_key(table, key)) return 0;
    }
    return 1;
}

static int insert_key(Table *table, int key)
{
    const long index = probe_insert(table, key);
    if (index < 0) return 0;
    table->slots[(size_t)index] = key;
    ++table->size;

    if (table->size * 2u >= table->capacity) return rehash(table);
    return 1;
}

static void write_i64_le(uint8_t *output, size_t *offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned int byte = 0u; byte < 8u; ++byte) {
        output[(*offset)++] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8u;
    }
}

int64_t quadratic_probing_hash_table(const int64_t *values, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2u || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 1 || values[0] > MAX_INITIAL_CAPACITY ||
        values[1] < 0 || values[1] > MAX_OPERATIONS) return -1;

    const size_t initial_capacity = (size_t)values[0];
    const size_t operation_count = (size_t)values[1];
    if (length != 2u + 2u * operation_count) return -1;

    Table table = {{0}, initial_capacity, 0u};
    bool active[MAX_TABLE_CAPACITY + 1u] = {false};
    int64_t find_results[MAX_OPERATIONS] = {0};
    size_t find_count = 0u;

    for (size_t operation_index = 0u; operation_index < operation_count; ++operation_index) {
        const int64_t operation = values[2u + 2u * operation_index];
        const int64_t key_value = values[3u + 2u * operation_index];
        if (operation < OP_INSERT || operation > OP_FIND || key_value < 1 || key_value > 64)
            return -1;
        const int key = (int)key_value;

        if (operation == OP_INSERT) {
            if (active[key]) return -1;
            if (!insert_key(&table, key)) return -1;
            active[key] = true;
        } else if (operation == OP_REMOVE) {
            if (!active[key]) return -1;
            const long index = probe_find(&table, key);
            if (index < 0) return -1;
            table.slots[(size_t)index] = -1;
            active[key] = false;
            --table.size;
        } else {
            const long index = probe_find(&table, key);
            /* Source find() treats index zero as its notPresent sentinel. */
            find_results[find_count++] = index <= 0 ? 0 : table.slots[(size_t)index];
        }
    }

    const size_t output_elements = 3u + find_count + table.capacity;
    const size_t output_bytes = output_elements * 8u;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || output_capacity < output_bytes) return -2;

    size_t offset = 0u;
    write_i64_le(output, &offset, (int64_t)table.capacity);
    write_i64_le(output, &offset, (int64_t)table.size);
    write_i64_le(output, &offset, (int64_t)find_count);
    for (size_t index = 0u; index < find_count; ++index)
        write_i64_le(output, &offset, find_results[index]);
    for (size_t index = 0u; index < table.capacity; ++index)
        write_i64_le(output, &offset, (int64_t)table.slots[index]);
    return (int64_t)offset;
}
