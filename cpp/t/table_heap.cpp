#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define MAX_OPS 256
#define MAP_CAPACITY 128
#define NIL_VALUE INT64_MIN

typedef struct { int32_t id, priority; size_t index; uint8_t state; } map_entry;

static size_t map_find(const map_entry *map, int32_t id) {
    size_t slot = ((uint32_t)id * UINT32_C(2654435761)) & (MAP_CAPACITY - 1);
    for (size_t n = 0; n < MAP_CAPACITY; ++n) {
        if (map[slot].state == 0) return MAP_CAPACITY;
        if (map[slot].state == 1 && map[slot].id == id) return slot;
        slot = (slot + 1) & (MAP_CAPACITY - 1);
    }
    return MAP_CAPACITY;
}

static size_t map_insert(map_entry *map, int32_t id, int32_t priority, size_t index) {
    size_t slot = ((uint32_t)id * UINT32_C(2654435761)) & (MAP_CAPACITY - 1);
    size_t tombstone = MAP_CAPACITY;
    for (size_t n = 0; n < MAP_CAPACITY; ++n) {
        if (map[slot].state == 2 && tombstone == MAP_CAPACITY) tombstone = slot;
        if (map[slot].state == 0) {
            if (tombstone != MAP_CAPACITY) slot = tombstone;
            map[slot] = map_entry{id, priority, index, 1};
            return slot;
        }
        if (map[slot].state == 1 && map[slot].id == id) return slot;
        slot = (slot + 1) & (MAP_CAPACITY - 1);
    }
    if (tombstone != MAP_CAPACITY) { map[tombstone] = map_entry{id, priority, index, 1}; return tombstone; }
    return MAP_CAPACITY;
}

static void map_remove(map_entry *map, size_t slot) { map[slot].state = 2; }
static int32_t priority_of(const map_entry *map, int32_t id) { return map[map_find(map, id)].priority; }

static void swap_ids(int32_t *heap, map_entry *map, size_t a, size_t b, int update_indices) {
    int32_t value = heap[a]; heap[a] = heap[b]; heap[b] = value;
    if (update_indices) {
        map[map_find(map, heap[a])].index = a;
        map[map_find(map, heap[b])].index = b;
    }
}

static void down(int32_t *heap, size_t count, map_entry *map, size_t index, int update_indices) {
    for (;;) {
        size_t left = index * 2 + 1;
        if (left >= count) return;
        size_t child = left + 1;
        if (child >= count || priority_of(map, heap[left]) < priority_of(map, heap[child])) child = left;
        if (priority_of(map, heap[child]) >= priority_of(map, heap[index])) return;
        swap_ids(heap, map, index, child, update_indices);
        index = child;
    }
}

static void up(int32_t *heap, map_entry *map, size_t index) {
    while (index > 0) {
        size_t parent = (index - 1) / 2;
        if (priority_of(map, heap[index]) >= priority_of(map, heap[parent])) return;
        swap_ids(heap, map, index, parent, 1);
        index = parent;
    }
}

static void store_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

extern "C" int64_t table_heap(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 1155) return -1;
    if (input[0] < 0 || input[0] > MAX_ITEMS) return -1;
    size_t initial = (size_t)input[0], op_index = 1 + 2 * initial;
    if (length <= op_index || input[op_index] < 0 || input[op_index] > MAX_OPS) return -1;
    size_t op_count = (size_t)input[op_index];
    if (length != 2 + 2 * initial + 4 * op_count || length > 1154) return -1;

    int32_t heap[MAX_ITEMS]; map_entry map[MAP_CAPACITY] = {{0}}; size_t count = initial;
    for (size_t i = 0; i < initial; ++i) {
        int64_t id = input[1 + 2 * i], priority = input[2 + 2 * i];
        if (id < INT32_MIN || id > INT32_MAX || priority < INT32_MIN || priority > INT32_MAX) return -1;
        if (map_find(map, (int32_t)id) != MAP_CAPACITY) return -1;
        heap[i] = (int32_t)id;
        if (map_insert(map, (int32_t)id, (int32_t)priority, 0) == MAP_CAPACITY) return -1;
    }
    for (size_t parent = count / 2; parent > 0; --parent) down(heap, count, map, parent - 1, 0);
    for (size_t i = 0; i < count; ++i) map[map_find(map, heap[i])].index = i;

    int64_t answers[MAX_OPS]; size_t cursor = op_index + 1;
    for (size_t oi = 0; oi < op_count; ++oi) {
        int64_t op = input[cursor], a = input[cursor + 1], b = input[cursor + 2], c = input[cursor + 3]; cursor += 4;
        if (op < 0 || op > 9) return -1;
        if (op == 0) {
            if (a < INT32_MIN || a > INT32_MAX || b < INT32_MIN || b > INT32_MAX || c != 0 || count == MAX_ITEMS || map_find(map, (int32_t)a) != MAP_CAPACITY) return -1;
            heap[count] = (int32_t)a;
            if (map_insert(map, (int32_t)a, (int32_t)b, count) == MAP_CAPACITY) return -1;
            ++count; up(heap, map, count - 1); answers[oi] = NIL_VALUE;
        } else if (op == 1) {
            if (a != 0 || b != 0 || c != 0) return -1;
            answers[oi] = count == 0 ? NIL_VALUE : heap[0];
        } else if (op == 2) {
            if (a != 0 || b != 0 || c != 0 || count == 0) return -1;
            int32_t removed = heap[0]; size_t old_slot = map_find(map, removed); answers[oi] = removed;
            swap_ids(heap, map, 0, count - 1, 1); --count;
            map_remove(map, old_slot);
            if (count > 0) down(heap, count, map, 0, 1);
        } else if (op == 3 || op == 4) {
            if (a != 0 || b != 0 || c != 0) return -1;
            answers[oi] = op == 3 ? (int64_t)count : (count == 0 ? 1 : 0);
        } else if (op == 5) {
            if (a < INT32_MIN || a > INT32_MAX || b != 0 || c != 0) return -1;
            size_t slot = map_find(map, (int32_t)a); answers[oi] = slot == MAP_CAPACITY ? NIL_VALUE : (int64_t)map[slot].index + 1;
        } else if (op == 6 || op == 7) {
            if (a < INT32_MIN || a > INT32_MAX || b < INT32_MIN || b > INT32_MAX || c != 0) return -1;
            size_t slot = map_find(map, (int32_t)a);
            if (slot == MAP_CAPACITY || (op == 6 && b > map[slot].priority) || (op == 7 && b < map[slot].priority)) return -1;
            map[slot].priority = (int32_t)b;
            if (op == 6) up(heap, map, map[slot].index); else down(heap, count, map, map[slot].index, 1);
            answers[oi] = NIL_VALUE;
        } else if (op == 8) {
            if (a < INT32_MIN || a > INT32_MAX || b < INT32_MIN || b > INT32_MAX || c < INT32_MIN || c > INT32_MAX) return -1;
            size_t old_slot = map_find(map, (int32_t)a), new_slot = map_find(map, (int32_t)b);
            if (old_slot == MAP_CAPACITY || (new_slot != MAP_CAPACITY && ((int32_t)b != (int32_t)a || c != map[old_slot].priority))) return -1;
            if (new_slot == MAP_CAPACITY) {
                size_t index = map[old_slot].index; int32_t old_priority = map[old_slot].priority;
                map_remove(map, old_slot); map_insert(map, (int32_t)b, (int32_t)c, index); heap[index] = (int32_t)b;
                if ((int32_t)c < old_priority) up(heap, map, index); else down(heap, count, map, index, 1);
            }
            answers[oi] = NIL_VALUE;
        } else {
            if (a < INT32_MIN || a > INT32_MAX || b != 0 || c != 0) return -1;
            size_t slot = map_find(map, (int32_t)a); if (slot == MAP_CAPACITY) return -1;
            size_t index = map[slot].index; int32_t removed_priority = map[slot].priority; --count;
            if (index != count) {
                heap[index] = heap[count]; map[map_find(map, heap[index])].index = index;
                if (priority_of(map, heap[index]) < removed_priority) up(heap, map, index); else down(heap, count, map, index, 1);
            }
            map_remove(map, slot); answers[oi] = NIL_VALUE;
        }
    }
    size_t bytes = op_count * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < op_count; ++i) store_i64(output, i * 8, answers[i]);
    return (int64_t)bytes;
}
