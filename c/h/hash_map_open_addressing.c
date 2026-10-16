#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 256
#define MAX_KEYS 64
#define MAX_CAPACITY 1024
#define MAX_INPUT_LENGTH (1 + 3 * MAX_OPERATIONS)
#define VALUE_OFFSET INT64_C(1000001)

typedef struct { int state; int64_t key; int64_t value; } Entry;

static void place(Entry *table, size_t capacity, int64_t key, int64_t value) {
    size_t index = (size_t)(key % (int64_t)capacity);
    for (size_t probe = 0; probe < capacity; ++probe) {
        if (table[index].state != 1) {
            table[index].state = 1;
            table[index].key = key;
            table[index].value = value;
            return;
        }
        if (table[index].key == key) { table[index].value = value; return; }
        index = (index + 1) % capacity;
    }
}

static void resize_table(Entry *table, size_t *capacity, size_t new_capacity, size_t *size) {
    Entry old[MAX_CAPACITY] = {{0}};
    size_t old_capacity = *capacity;
    for (size_t i = 0; i < old_capacity; ++i) old[i] = table[i];
    for (size_t i = 0; i < new_capacity; ++i) table[i] = (Entry){0};
    *capacity = new_capacity;
    *size = 0;
    for (size_t i = 0; i < old_capacity; ++i) {
        if (old[i].state == 1) { place(table, new_capacity, old[i].key, old[i].value); ++*size; }
    }
}

static size_t find_key(const Entry *table, size_t capacity, int64_t key,
                       size_t *first_tombstone, int *tomb_before_match) {
    size_t index = (size_t)(key % (int64_t)capacity);
    *first_tombstone = capacity;
    *tomb_before_match = 0;
    for (size_t probe = 0; probe < capacity; ++probe) {
        if (table[index].state == 0) return capacity;
        if (table[index].state == 2) {
            if (*first_tombstone == capacity) *first_tombstone = index;
        } else if (table[index].key == key) {
            *tomb_before_match = *first_tombstone != capacity;
            return index;
        }
        index = (index + 1) % capacity;
    }
    return capacity;
}

int64_t hash_map_open_addressing(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    int64_t q = input[0];
    if (q < 0 || q > MAX_OPERATIONS || length != 1 + 3 * (size_t)q) return -1;
    Entry table[MAX_CAPACITY] = {{0}};
    size_t capacity = 8, size = 0;
    int64_t query_sum = 0, query_index = 0;

    for (size_t opi = 0; opi < (size_t)q; ++opi) {
        int64_t opcode = input[1 + 3 * opi];
        int64_t key = input[2 + 3 * opi];
        int64_t value = input[3 + 3 * opi];
        if (opcode == 0) {
            if (key < 0 || key > 1000000 || value < -1000000 || value > 1000000) return -1;
            size_t tomb; int tomb_before;
            size_t before = find_key(table, capacity, key, &tomb, &tomb_before);
            if (before == capacity && size >= MAX_KEYS) return -1;
            if (size >= capacity * 3 / 4) {
                if (capacity * 2 > MAX_CAPACITY) return -1;
                resize_table(table, &capacity, capacity * 2, &size);
            }
            size_t found = find_key(table, capacity, key, &tomb, &tomb_before);
            if (found != capacity) {
                if (tomb_before) return -1;
                table[found].value = value;
            } else {
                size_t index = (size_t)(key % (int64_t)capacity);
                size_t target = tomb;
                for (size_t probe = 0; probe < capacity; ++probe) {
                    if (table[index].state == 0) { if (target == capacity) target = index; break; }
                    index = (index + 1) % capacity;
                }
                if (target == capacity) return -1;
                table[target] = (Entry){1, key, value};
                ++size;
            }
        } else if (opcode == 1 || opcode == 2 || opcode == 3) {
            if (key < 0 || key > 1000000 || value != 0) return -1;
            size_t tomb; int tomb_before;
            size_t found = find_key(table, capacity, key, &tomb, &tomb_before);
            if ((opcode == 1 || opcode == 2) && found == capacity) return -1;
            if (opcode == 1) {
                ++query_index;
                query_sum += query_index * (table[found].value + VALUE_OFFSET);
            } else if (opcode == 2) {
                table[found].state = 2;
                --size;
                if (capacity > 8 && size < capacity * 3 / 8)
                    resize_table(table, &capacity, capacity / 2, &size);
            } else {
                ++query_index;
                query_sum += query_index * ((found != capacity) + VALUE_OFFSET);
            }
        } else if (opcode == 4) {
            if (key != 0 || value != 0) return -1;
            ++query_index;
            query_sum += query_index * ((int64_t)size + VALUE_OFFSET);
        } else return -1;
    }

    int64_t keys[MAX_KEYS], values[MAX_KEYS];
    size_t count = 0;
    for (size_t i = 0; i < capacity; ++i) if (table[i].state == 1) {
        size_t at = count++;
        while (at > 0 && keys[at - 1] > table[i].key) {
            keys[at] = keys[at - 1]; values[at] = values[at - 1]; --at;
        }
        keys[at] = table[i].key; values[at] = table[i].value;
    }
    int64_t final_state = 0;
    for (size_t i = 0; i < count; ++i)
        final_state += (int64_t)(i + 1) * (keys[i] + 1) * (values[i] + VALUE_OFFSET);
    return query_sum + final_state + (int64_t)size;
}
