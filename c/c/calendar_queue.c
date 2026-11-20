#include <stddef.h>
#include <stdint.h>

#define CQ_MAX_OPS 128
#define CQ_MAX_LIVE 64
#define CQ_MAX_BUCKETS 64
#define CQ_MAX_PRIORITY 1000000
#define CQ_MAX_INPUT (1 + 2 * CQ_MAX_OPS + 1)

typedef struct {
    int64_t priority;
    int64_t event_id;
    int next;
    int active;
} CqEvent;

typedef struct {
    CqEvent events[CQ_MAX_LIVE];
    int heads[CQ_MAX_BUCKETS];
    int bucket_count;
    int live_count;
    int64_t next_id;
    int64_t last_priority;
    int last_bucket;
    int64_t width_num;
    int64_t width_den;
    int64_t bucket_top_num;
    int64_t bucket_top_den;
} CqState;

static void cq_put_i64(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[word * 8 + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

static int cq_less_event(const CqEvent *left, const CqEvent *right) {
    return left->priority < right->priority
        || (left->priority == right->priority && left->event_id < right->event_id);
}

static int64_t cq_gcd(int64_t a, int64_t b) {
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static int64_t cq_virtual_bucket(const CqState *state, int64_t priority) {
    return priority * state->width_den / state->width_num;
}

static int cq_bucket_index(const CqState *state, int64_t priority) {
    return (int)(cq_virtual_bucket(state, priority) % state->bucket_count);
}

static void cq_reset_cursor(CqState *state, int64_t priority) {
    const int64_t virtual_bucket = cq_virtual_bucket(state, priority);
    state->last_bucket = (int)(virtual_bucket % state->bucket_count);
    state->bucket_top_num = (2 * virtual_bucket + 3) * state->width_num;
    state->bucket_top_den = 2 * state->width_den;
}

static void cq_insert_slot(CqState *state, int slot) {
    const int bucket_index = cq_bucket_index(state, state->events[slot].priority);
    int current = state->heads[bucket_index];
    int previous = -1;
    while (current >= 0 && cq_less_event(&state->events[current], &state->events[slot])) {
        previous = current;
        current = state->events[current].next;
    }
    state->events[slot].next = current;
    if (previous < 0) {
        state->heads[bucket_index] = slot;
    } else {
        state->events[previous].next = slot;
    }
}

static void cq_new_width(const CqState *state, int64_t *width_num, int64_t *width_den) {
    CqEvent sorted[CQ_MAX_LIVE];
    int count = 0;
    for (int i = 0; i < CQ_MAX_LIVE; ++i) {
        if (!state->events[i].active) continue;
        int at = count;
        while (at > 0 && cq_less_event(&state->events[i], &sorted[at - 1])) {
            sorted[at] = sorted[at - 1];
            --at;
        }
        sorted[at] = state->events[i];
        ++count;
    }
    if (count < 2) {
        *width_num = 1;
        *width_den = 1;
        return;
    }
    int samples = count <= 5 ? count : 5 + count / 10;
    if (samples > 25) samples = 25;
    int64_t gap_sum = 0;
    for (int i = 0; i + 1 < samples; ++i) {
        gap_sum += sorted[i + 1].priority - sorted[i].priority;
    }
    const int gap_count = samples - 1;
    if (gap_sum == 0) {
        *width_num = 1;
        *width_den = 1;
        return;
    }
    int64_t kept_sum = 0;
    int kept_count = 0;
    for (int i = 0; i < gap_count; ++i) {
        const int64_t gap = sorted[i + 1].priority - sorted[i].priority;
        if (gap * gap_count <= 2 * gap_sum) {
            kept_sum += gap;
            ++kept_count;
        }
    }
    if (kept_sum == 0 || kept_count == 0) {
        *width_num = 1;
        *width_den = 1;
        return;
    }
    int64_t numerator = 3 * kept_sum;
    int64_t denominator = kept_count;
    const int64_t divisor = cq_gcd(numerator, denominator);
    *width_num = numerator / divisor;
    *width_den = denominator / divisor;
}

static void cq_resize(CqState *state, int new_count) {
    int64_t new_num, new_den;
    cq_new_width(state, &new_num, &new_den);
    state->bucket_count = new_count;
    state->width_num = new_num;
    state->width_den = new_den;
    for (int i = 0; i < CQ_MAX_BUCKETS; ++i) state->heads[i] = -1;
    cq_reset_cursor(state, state->last_priority);
    for (int slot = 0; slot < CQ_MAX_LIVE; ++slot) {
        if (state->events[slot].active) cq_insert_slot(state, slot);
    }
}

static int cq_enqueue(CqState *state, int64_t priority) {
    if (priority < 0 || priority > CQ_MAX_PRIORITY || priority < state->last_priority
            || state->live_count >= CQ_MAX_LIVE) return 0;
    int slot = -1;
    for (int i = 0; i < CQ_MAX_LIVE; ++i) {
        if (!state->events[i].active) { slot = i; break; }
    }
    if (slot < 0) return 0;
    state->events[slot].priority = priority;
    state->events[slot].event_id = state->next_id++;
    state->events[slot].active = 1;
    ++state->live_count;
    cq_insert_slot(state, slot);
    if (state->live_count > 2 * state->bucket_count) {
        cq_resize(state, state->bucket_count * 2);
    }
    return 1;
}

static int cq_dequeue(CqState *state, CqEvent *result) {
    if (state->live_count == 0) return 0;
    int bucket = state->last_bucket;
    for (;;) {
        const int slot = state->heads[bucket];
        if (slot >= 0
                && state->events[slot].priority * state->bucket_top_den
                    < state->bucket_top_num) {
            *result = state->events[slot];
            state->heads[bucket] = state->events[slot].next;
            state->events[slot].active = 0;
            --state->live_count;
            state->last_bucket = bucket;
            state->last_priority = result->priority;
            const int bottom = state->bucket_count / 2 - 2;
            if (state->live_count < bottom && state->bucket_count > 2) {
                cq_resize(state, state->bucket_count / 2);
            }
            return 1;
        }
        ++bucket;
        if (bucket == state->bucket_count) bucket = 0;
        state->bucket_top_num += 2 * state->width_num;
        if (bucket == state->last_bucket) {
            int minimum = -1;
            for (int i = 0; i < state->bucket_count; ++i) {
                const int head = state->heads[i];
                if (head >= 0 && (minimum < 0
                        || cq_less_event(&state->events[head], &state->events[minimum]))) {
                    minimum = head;
                }
            }
            if (minimum < 0) return 0;
            state->last_priority = state->events[minimum].priority;
            cq_reset_cursor(state, state->last_priority);
            bucket = state->last_bucket;
        }
    }
}

int64_t calendar_queue(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > CQ_MAX_INPUT) return -1;
    const int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > CQ_MAX_OPS
            || length != (size_t)(1 + 2 * operation_count)) return -1;

    CqState state = {0};
    state.bucket_count = 2;
    state.width_num = 1;
    state.width_den = 1;
    state.bucket_top_num = 3;
    state.bucket_top_den = 2;
    for (int i = 0; i < CQ_MAX_BUCKETS; ++i) state.heads[i] = -1;
    int64_t trace[2 * CQ_MAX_OPS];
    int dequeue_count = 0;
    for (int64_t step = 0; step < operation_count; ++step) {
        const int64_t opcode = input[1 + 2 * (size_t)step];
        const int64_t argument = input[2 + 2 * (size_t)step];
        if (opcode == 1) {
            if (!cq_enqueue(&state, argument)) return -1;
        } else if (opcode == 2) {
            if (argument != 0) return -1;
            CqEvent event;
            if (!cq_dequeue(&state, &event)) return -1;
            trace[2 * dequeue_count] = event.event_id;
            trace[2 * dequeue_count + 1] = event.priority;
            ++dequeue_count;
        } else {
            return -1;
        }
    }

    const size_t bytes = (size_t)(1 + 2 * dequeue_count) * 8;
    if (output == NULL || capacity < bytes) return -2;
    cq_put_i64(output, 0, dequeue_count);
    for (int i = 0; i < 2 * dequeue_count; ++i) {
        cq_put_i64(output, (size_t)(i + 1), trace[i]);
    }
    return (int64_t)bytes;
}
