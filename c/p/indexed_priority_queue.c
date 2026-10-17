#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#define MAX_EVENTS 256
#define MAX_ACTIVE 64
#define MAX_INPUT_VALUES 1538

static void store_i64_le(uint8_t *output, size_t position, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

static bool key_in_use(const int64_t *heap_ids, const int64_t *heap_keys,
                       size_t size, int64_t key, int64_t except_id)
{
    for (size_t index = 0; index < size; ++index)
        if (heap_ids[index] != except_id && heap_keys[index] == key) return true;
    return false;
}

static bool sift_up(int64_t *heap_ids, int64_t *heap_keys, int32_t *positions, size_t index)
{
    const int64_t item_id = heap_ids[index];
    const int64_t item_key = heap_keys[index];
    const size_t original = index;
    while (index > 0) {
        const size_t parent = (index - 1) / 2;
        if (item_key >= heap_keys[parent]) break;
        heap_ids[index] = heap_ids[parent];
        heap_keys[index] = heap_keys[parent];
        positions[heap_ids[index]] = (int32_t)index;
        index = parent;
    }
    heap_ids[index] = item_id;
    heap_keys[index] = item_key;
    positions[item_id] = (int32_t)index;
    return index != original;
}

static void sift_down(int64_t *heap_ids, int64_t *heap_keys, int32_t *positions,
                      size_t size, size_t index)
{
    const int64_t item_id = heap_ids[index];
    const int64_t item_key = heap_keys[index];
    const size_t half = size / 2;
    while (index < half) {
        size_t child = index * 2 + 1;
        const size_t right = child + 1;
        if (right < size && heap_keys[child] > heap_keys[right]) child = right;
        if (item_key <= heap_keys[child]) break;
        heap_ids[index] = heap_ids[child];
        heap_keys[index] = heap_keys[child];
        positions[heap_ids[index]] = (int32_t)index;
        index = child;
    }
    heap_ids[index] = item_id;
    heap_keys[index] = item_key;
    positions[item_id] = (int32_t)index;
}

static void remove_at(size_t *size, int64_t *heap_ids, int64_t *heap_keys,
                      int32_t *positions, size_t index)
{
    const size_t new_size = *size - 1;
    const int64_t removed_id = heap_ids[index];
    const int64_t moved_id = heap_ids[new_size];
    const int64_t moved_key = heap_keys[new_size];
    *size = new_size;
    positions[removed_id] = -1;
    if (index == new_size) return;

    heap_ids[index] = moved_id;
    heap_keys[index] = moved_key;
    positions[moved_id] = (int32_t)index;
    if (!sift_up(heap_ids, heap_keys, positions, index))
        sift_down(heap_ids, heap_keys, positions, *size, index);
}

int64_t indexed_priority_queue(const int64_t *values, size_t length,
                               uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 0 || values[0] > MAX_EVENTS) return -1;
    const size_t event_count = (size_t)values[0];
    if (length != 1 + 6 * event_count) return -1;
    if (event_count == 0) return 0;

    int64_t heap_ids[MAX_ACTIVE], heap_keys[MAX_ACTIVE];
    int32_t positions[MAX_ACTIVE];
    int64_t records[MAX_EVENTS][6];
    for (size_t id = 0; id < MAX_ACTIVE; ++id) positions[id] = -1;
    size_t size = 0;

    for (size_t event_index = 0; event_index < event_count; ++event_index) {
        const size_t start = 1 + event_index * 6;
        const int64_t opcode = values[start];
        const int64_t element_id = values[start + 1];
        const int64_t key = values[start + 2];
        if (values[start + 3] != 0 || values[start + 4] != 0 || values[start + 5] != 0) return -1;

        int64_t status = 1, result_id = 0, result_key = 0;
        if (opcode == 0) {
            if (element_id < 0 || element_id >= MAX_ACTIVE || key < INT32_MIN || key > INT32_MAX ||
                positions[element_id] >= 0 || size >= MAX_ACTIVE ||
                key_in_use(heap_ids, heap_keys, size, key, -1)) return -1;
            heap_ids[size] = element_id;
            heap_keys[size] = key;
            positions[element_id] = (int32_t)size;
            ++size;
            (void)sift_up(heap_ids, heap_keys, positions, size - 1);
        } else if (opcode == 1 || opcode == 2) {
            if (element_id != 0 || key != 0) return -1;
            if (size == 0) {
                status = 0;
            } else {
                result_id = heap_ids[0];
                result_key = heap_keys[0];
                if (opcode == 2) remove_at(&size, heap_ids, heap_keys, positions, 0);
            }
        } else if (opcode == 3 || opcode == 4) {
            if (element_id < 0 || element_id >= MAX_ACTIVE || key != 0) return -1;
            const int32_t position = positions[element_id];
            status = position >= 0 ? 1 : 0;
            if (opcode == 3 && position >= 0)
                remove_at(&size, heap_ids, heap_keys, positions, (size_t)position);
        } else if (opcode >= 5 && opcode <= 7) {
            if (element_id < 0 || element_id >= MAX_ACTIVE || key < INT32_MIN || key > INT32_MAX) return -1;
            const int32_t position = positions[element_id];
            if (position < 0) return -1;
            const int64_t old_key = heap_keys[position];
            if ((opcode == 6 && key >= old_key) || (opcode == 7 && key <= old_key) ||
                key_in_use(heap_ids, heap_keys, size, key, element_id)) return -1;
            heap_keys[position] = key;
            if (opcode == 6) {
                (void)sift_up(heap_ids, heap_keys, positions, (size_t)position);
            } else if (opcode == 7) {
                sift_down(heap_ids, heap_keys, positions, size, (size_t)position);
            } else if (!sift_up(heap_ids, heap_keys, positions, (size_t)position)) {
                sift_down(heap_ids, heap_keys, positions, size, (size_t)position);
            }
        } else if (opcode == 8 || opcode == 9 || opcode == 10) {
            if (element_id != 0 || key != 0) return -1;
            if (opcode == 8) {
                for (size_t index = 0; index < size; ++index) positions[heap_ids[index]] = -1;
                size = 0;
            } else if (opcode == 9) {
                result_id = (int64_t)size;
            } else {
                result_id = size == 0 ? 1 : 0;
            }
        } else {
            return -1;
        }

        records[event_index][0] = status;
        records[event_index][1] = result_id;
        records[event_index][2] = result_key;
        records[event_index][3] = (int64_t)size;
        records[event_index][4] = size == 0 ? 0 : heap_ids[0];
        records[event_index][5] = size == 0 ? 0 : heap_keys[0];
    }

    const size_t required = event_count * 48;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t event = 0; event < event_count; ++event)
        for (size_t field = 0; field < 6; ++field)
            store_i64_le(output, event * 48 + field * 8, records[event][field]);
    return (int64_t)required;
}
