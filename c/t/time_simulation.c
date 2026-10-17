#include <stddef.h>
#include <stdint.h>

#define MAX_ACTIONS 4096
#define MAX_INPUT_LENGTH 8194
#define MAX_EVENTS 1024
#define MAX_EVENT_ID UINT64_C(4294967295)
static uint64_t hash_word(uint64_t hash, uint64_t word) {
    for (unsigned shift = 0; shift < 64; shift += 8) {
        hash ^= (word >> shift) & UINT64_C(255);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}
int64_t time_simulation(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t action_count = values[0];
    if (action_count < 0 || action_count > MAX_ACTIONS || length != 1u + 2u * (size_t)action_count) return -1;
    uint64_t hash = hash_word(UINT64_C(14695981039346656037), (uint64_t)action_count);
    int64_t now = 0;
    uint64_t next_id = 1;
    size_t active_count = 0, total_processed = 0, fired_count = 0;
    int active[MAX_EVENTS] = {0};
    int64_t timestamps[MAX_EVENTS] = {0};
    uint64_t event_ids[MAX_EVENTS] = {0};
    /* Reused queue slots can fire repeatedly, so trace storage spans all actions. */
    uint64_t fired_ids[MAX_ACTIONS] = {0};
    int64_t fired_times[MAX_ACTIONS] = {0};
    for (size_t action = 0; action < (size_t)action_count; ++action) {
        const int64_t opcode = values[1 + 2 * action];
        const int64_t operand = values[2 + 2 * action];
        uint64_t result = 0;
        if (opcode == 0) {
            if (operand < 0 || operand < now) return -1;
            if (active_count < MAX_EVENTS) {
                size_t slot = 0;
                while (slot < MAX_EVENTS && active[slot]) ++slot;
                event_ids[slot] = next_id;
                timestamps[slot] = operand;
                active[slot] = 1;
                ++active_count;
                result = next_id++;
                if (next_id > MAX_EVENT_ID) next_id = 1;
            }
        } else if (opcode == 1) {
            if (operand < 1 || (uint64_t)operand > MAX_EVENT_ID) return -1;
            for (size_t slot = 0; slot < MAX_EVENTS; ++slot) if (active[slot] && event_ids[slot] == (uint64_t)operand) {
                active[slot] = 0; --active_count; result = 1; break;
            }
        } else if (opcode == 2) {
            if (operand < 0 || operand < now) return -1;
            size_t processed = 0;
            for (;;) {
                size_t chosen = MAX_EVENTS;
                int64_t earliest = 0;
                for (size_t slot = 0; slot < MAX_EVENTS; ++slot)
                    if (active[slot] && timestamps[slot] <= operand && (chosen == MAX_EVENTS || timestamps[slot] < earliest)) {
                        chosen = slot; earliest = timestamps[slot];
                    }
                if (chosen == MAX_EVENTS) break;
                now = timestamps[chosen];
                active[chosen] = 0; --active_count;
                fired_ids[fired_count] = event_ids[chosen]; fired_times[fired_count] = timestamps[chosen]; ++fired_count;
                ++processed; ++total_processed;
            }
            now = operand; result = processed;
        } else if (opcode == 3) {
            if (operand != 0) return -1;
            result = (uint64_t)now;
        } else if (opcode == 4) {
            if (operand != 0) return -1;
            result = active_count == 0 ? 1 : 0;
        } else return -1;
        hash = hash_word(hash, result);
    }
    hash = hash_word(hash, fired_count);
    for (size_t i = 0; i < fired_count; ++i) { hash = hash_word(hash, fired_ids[i]); hash = hash_word(hash, (uint64_t)fired_times[i]); }
    hash = hash_word(hash, (uint64_t)now);
    hash = hash_word(hash, active_count);
    hash = hash_word(hash, total_processed);
    return (int64_t)(hash & UINT64_C(0x7FFFFFFFFFFFFFFF));
}
