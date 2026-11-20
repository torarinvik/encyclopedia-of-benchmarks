module buddy_system_allocator;
const usz ARENA = 256;
const usz MAX_ORDER = 8;
const usz MAX_OPS = 64;
const usz MAX_IDS = 32;
const usz MAX_INPUT_WORDS = 194;
const usz MAX_OUTPUT_WORDS = 3 * MAX_OPS + 1 + 2 * ARENA;

fn long buddy_system_allocator(long* values, usz length, char* output, usz capacity)
        @export("buddy_system_allocator") {
    if (values == null || length < 1 || length > MAX_INPUT_WORDS) return -1;
    long raw_count = values[0];
    if (raw_count < 0 || raw_count > (long)MAX_OPS || length != 1 + 3 * (usz)raw_count) return -1;
    usz count = (usz)raw_count;

    bool[(MAX_ORDER + 1) * ARENA] free_blocks;
    bool[MAX_IDS] active;
    long[MAX_IDS] allocation_base;
    long[MAX_IDS] allocation_order;
    long[MAX_OUTPUT_WORDS] staged;
    for (usz i = 0; i < (MAX_ORDER + 1) * ARENA; i++) free_blocks[i] = false;
    for (usz i = 0; i < MAX_IDS; i++) active[i] = false;
    free_blocks[MAX_ORDER * ARENA] = true;
    usz staged_words = 0;

    for (usz i = 0; i < count; i++) {
        long opcode = values[1 + 3 * i];
        long raw_id = values[2 + 3 * i];
        long argument = values[3 + 3 * i];
        if (raw_id < 0 || raw_id >= (long)MAX_IDS) return -1;
        usz id = (usz)raw_id;
        if (opcode == 0) {
            if (argument < 1 || argument > (long)ARENA || active[id]) return -1;
            usz target = 0;
            usz rounded = 1;
            while (rounded < (usz)argument) { rounded *= 2; target += 1; }
            usz found_order = MAX_ORDER + 1;
            usz found_base = ARENA;
            for (usz order = target; order <= MAX_ORDER; order++) {
                usz size = (usz)1 << order;
                for (usz base = 0; base + size <= ARENA; base += size) {
                    if (free_blocks[order * ARENA + base]) {
                        found_order = order;
                        found_base = base;
                        break;
                    }
                }
                if (found_order <= MAX_ORDER) break;
            }
            if (found_order > MAX_ORDER) {
                staged[staged_words++] = 0; staged[staged_words++] = -1; staged[staged_words++] = 0;
                continue;
            }
            free_blocks[found_order * ARENA + found_base] = false;
            while (found_order > target) {
                found_order -= 1;
                usz half = (usz)1 << found_order;
                free_blocks[found_order * ARENA + found_base + half] = true;
            }
            active[id] = true;
            allocation_base[id] = (long)found_base;
            allocation_order[id] = (long)target;
            staged[staged_words++] = 1;
            staged[staged_words++] = (long)found_base;
            staged[staged_words++] = (long)((usz)1 << target);
        } else if (opcode == 1) {
            if (argument != 0 || !active[id]) return -1;
            usz original_base = (usz)allocation_base[id];
            usz original_order = (usz)allocation_order[id];
            usz original_size = (usz)1 << original_order;
            active[id] = false;
            usz base = original_base;
            usz order = original_order;
            while (order < MAX_ORDER) {
                usz buddy = base ^ ((usz)1 << order);
                if (!free_blocks[order * ARENA + buddy]) break;
                free_blocks[order * ARENA + buddy] = false;
                if (buddy < base) base = buddy;
                order += 1;
            }
            free_blocks[order * ARENA + base] = true;
            staged[staged_words++] = 1;
            staged[staged_words++] = (long)original_base;
            staged[staged_words++] = (long)original_size;
        } else return -1;
    }

    usz count_index = staged_words;
    staged[staged_words++] = 0;
    for (usz base = 0; base < ARENA; base++) {
        for (usz order = MAX_ORDER + 1; order > 0;) {
            order -= 1;
            if (free_blocks[order * ARENA + base]) {
                staged[count_index] += 1;
                staged[staged_words++] = (long)base;
                staged[staged_words++] = (long)((usz)1 << order);
                break;
            }
        }
    }
    usz required = staged_words * 8;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < staged_words; i++) {
        ulong word = (ulong)staged[i];
        for (usz byte = 0; byte < 8; byte++) output[8 * i + byte] = (char)((word >> (8 * byte)) & 255);
    }
    return (long)required;
}
