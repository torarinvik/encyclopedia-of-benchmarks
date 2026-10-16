#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 512
#define MAX_ITEMS 128
#define MAX_ID 4095
#define MAX_INPUT_LENGTH (1 + 3 * MAX_OPERATIONS)
#define FNV_OFFSET UINT64_C(0xcbf29ce484222325)
#define FNV_PRIME UINT64_C(0x100000001b3)

static uint64_t hash_byte(uint64_t hash, uint8_t byte)
{
    return (hash ^ byte) * FNV_PRIME;
}

static uint64_t hash_i32(uint64_t hash, int64_t value)
{
    uint32_t bits = (uint32_t)value;
    for (unsigned shift = 0; shift < 32; shift += 8)
        hash = hash_byte(hash, (uint8_t)(bits >> shift));
    return hash;
}

static void swap_items(int64_t *ids, int64_t *priorities, int *positions, size_t first, size_t second)
{
    int64_t temporary = ids[first];
    ids[first] = ids[second];
    ids[second] = temporary;
    temporary = priorities[first];
    priorities[first] = priorities[second];
    priorities[second] = temporary;
    positions[ids[first]] = (int)first;
    positions[ids[second]] = (int)second;
}

static void heapify_up(int64_t *ids, int64_t *priorities, int *positions, size_t index)
{
    while (index > 0) {
        size_t parent = (index - 1) / 2;
        if (priorities[index] <= priorities[parent]) break;
        swap_items(ids, priorities, positions, index, parent);
        index = parent;
    }
}

static void heapify_down(int64_t *ids, int64_t *priorities, int *positions,
                         size_t heap_size, size_t index)
{
    for (;;) {
        size_t best = index;
        size_t left = 2 * index + 1;
        size_t right = left + 1;
        if (left < heap_size && priorities[left] > priorities[best]) best = left;
        if (right < heap_size && priorities[right] > priorities[best]) best = right;
        if (best == index) return;
        swap_items(ids, priorities, positions, index, best);
        index = best;
    }
}

static void erase_item(int64_t *ids, int64_t *priorities, int *positions,
                       size_t *heap_size, int64_t item_id)
{
    size_t index = (size_t)positions[item_id];
    size_t last = *heap_size - 1;
    positions[item_id] = -1;
    if (index != last) {
        ids[index] = ids[last];
        priorities[index] = priorities[last];
        positions[ids[index]] = (int)index;
    }
    *heap_size = last;
    if (index < *heap_size) {
        heapify_up(ids, priorities, positions, index);
        heapify_down(ids, priorities, positions, *heap_size, index);
    }
}

int64_t heap_generic(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    int64_t operation_count_value = values[0];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS ||
        length != 1 + 3 * (size_t)operation_count_value) return -1;

    int64_t ids[MAX_ITEMS] = {0};
    int64_t priorities[MAX_ITEMS] = {0};
    int positions[MAX_ID + 1];
    uint8_t used_ids[MAX_ID + 1] = {0};
    for (size_t i = 0; i <= MAX_ID; ++i) positions[i] = -1;
    size_t heap_size = 0;
    uint64_t hash = FNV_OFFSET;

    for (size_t operation = 0; operation < (size_t)operation_count_value; ++operation) {
        int64_t opcode = values[1 + 3 * operation];
        int64_t item_id = values[2 + 3 * operation];
        int64_t priority = values[3 + 3 * operation];
        int present = 0;
        int64_t returned_id = 0, returned_priority = 0;

        if (opcode == 0) {
            if (item_id < 0 || item_id > MAX_ID || priority < INT32_MIN || priority > INT32_MAX ||
                used_ids[item_id] || heap_size >= MAX_ITEMS) return -1;
            for (size_t i = 0; i < heap_size; ++i)
                if (priorities[i] == priority) return -1;
            used_ids[item_id] = 1;
            ids[heap_size] = item_id;
            priorities[heap_size] = priority;
            positions[item_id] = (int)heap_size;
            ++heap_size;
            heapify_up(ids, priorities, positions, heap_size - 1);
        } else if (opcode == 1 || opcode == 2) {
            if (item_id != 0 || priority != 0) return -1;
            if (heap_size != 0) {
                present = 1;
                returned_id = ids[0];
                returned_priority = priorities[0];
                if (opcode == 2) erase_item(ids, priorities, positions, &heap_size, returned_id);
            }
        } else if (opcode == 3) {
            if (item_id < 0 || item_id > MAX_ID || priority < INT32_MIN || priority > INT32_MAX ||
                positions[item_id] < 0) return -1;
            size_t index = (size_t)positions[item_id];
            for (size_t i = 0; i < heap_size; ++i)
                if (i != index && priorities[i] == priority) return -1;
            priorities[index] = priority;
            heapify_up(ids, priorities, positions, index);
            heapify_down(ids, priorities, positions, heap_size, index);
        } else if (opcode == 4) {
            if (item_id < 0 || item_id > MAX_ID || priority != 0 || positions[item_id] < 0) return -1;
            erase_item(ids, priorities, positions, &heap_size, item_id);
        } else {
            return -1;
        }

        hash = hash_byte(hash, (uint8_t)opcode);
        hash = hash_byte(hash, (uint8_t)present);
        if (present) {
            hash = hash_i32(hash, returned_id);
            hash = hash_i32(hash, returned_priority);
        }
    }
    return (int64_t)hash;
}
