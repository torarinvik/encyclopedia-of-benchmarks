#include <stddef.h>
#include <stdint.h>

enum { CF_BUCKETS = 8, CF_WIDTH = 4, CF_MAX_OPS = 32, CF_MAX_KICKS = 8 };

static size_t cf_delta(int64_t fingerprint) {
    return (size_t)(1 + ((5 * (size_t)fingerprint + 3) % 7));
}

static size_t cf_empty(const int64_t slots[CF_BUCKETS * CF_WIDTH], size_t bucket) {
    for (size_t slot = 0; slot < CF_WIDTH; ++slot)
        if (slots[bucket * CF_WIDTH + slot] == 0) return slot;
    return CF_WIDTH;
}

static void cf_write_i64(uint8_t *output, size_t index, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[index * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

static int cf_insert(int64_t slots[CF_BUCKETS * CF_WIDTH], size_t primary,
        int64_t fingerprint) {
    const size_t alternate = primary ^ cf_delta(fingerprint);
    size_t empty = cf_empty(slots, primary);
    if (empty < CF_WIDTH) {
        slots[primary * CF_WIDTH + empty] = fingerprint;
        return 1;
    }
    empty = cf_empty(slots, alternate);
    if (empty < CF_WIDTH) {
        slots[alternate * CF_WIDTH + empty] = fingerprint;
        return 1;
    }

    size_t current = primary;
    int64_t pending = fingerprint;
    for (size_t kick = 0; kick < CF_MAX_KICKS; ++kick) {
        const size_t position = current * CF_WIDTH;
        const int64_t evicted = slots[position];
        slots[position] = pending;
        pending = evicted;
        current ^= cf_delta(pending);
        empty = cf_empty(slots, current);
        if (empty < CF_WIDTH) {
            slots[current * CF_WIDTH + empty] = pending;
            return 1;
        }
    }
    return 0;
}

int64_t cuckoo_filter_operation_trace(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 98) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 1 || raw_count > CF_MAX_OPS) return -1;
    const size_t count = (size_t)raw_count;
    if (length != 1 + 3 * count) return -1;
    for (size_t i = 0; i < count; ++i) {
        const int64_t opcode = input[1 + 3 * i];
        const int64_t primary = input[2 + 3 * i];
        const int64_t fingerprint = input[3 + 3 * i];
        if (opcode < 0 || opcode > 2 || primary < 0 || primary >= CF_BUCKETS ||
                fingerprint < 1 || fingerprint > 15) return -1;
    }

    const size_t required = count * 8;
    if (output == NULL || capacity < required) return -2;

    int64_t slots[CF_BUCKETS * CF_WIDTH] = {0};
    int64_t statuses[CF_MAX_OPS];
    for (size_t i = 0; i < count; ++i) {
        const int64_t opcode = input[1 + 3 * i];
        const size_t primary = (size_t)input[2 + 3 * i];
        const int64_t fingerprint = input[3 + 3 * i];
        const size_t alternate = primary ^ cf_delta(fingerprint);
        if (opcode == 0) {
            if (!cf_insert(slots, primary, fingerprint)) return -3;
            statuses[i] = 1;
        } else if (opcode == 1) {
            int found = 0;
            for (size_t bucket_order = 0; bucket_order < 2 && !found; ++bucket_order) {
                const size_t bucket = bucket_order == 0 ? primary : alternate;
                for (size_t slot = 0; slot < CF_WIDTH; ++slot)
                    if (slots[bucket * CF_WIDTH + slot] == fingerprint) { found = 1; break; }
            }
            statuses[i] = found ? 1 : 0;
        } else {
            int removed = 0;
            for (size_t bucket_order = 0; bucket_order < 2 && !removed; ++bucket_order) {
                const size_t bucket = bucket_order == 0 ? primary : alternate;
                for (size_t slot = 0; slot < CF_WIDTH; ++slot) {
                    const size_t position = bucket * CF_WIDTH + slot;
                    if (slots[position] == fingerprint) {
                        slots[position] = 0;
                        removed = 1;
                        break;
                    }
                }
            }
            statuses[i] = removed ? 1 : 0;
        }
    }

    for (size_t i = 0; i < count; ++i) cf_write_i64(output, i, statuses[i]);
    return (int64_t)required;
}
