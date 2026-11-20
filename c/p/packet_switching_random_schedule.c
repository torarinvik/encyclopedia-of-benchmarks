#include <stddef.h>
#include <stdint.h>

#define MAX_QUEUES 4
#define MAX_BUFFER 4
#define MAX_SLOTS 8
#define MAX_PARSEABLE_INPUT 68
#define MAX_OUTPUT_BYTES 64
#define MAX_PRIORITY UINT64_C(4294967295)

typedef struct { int64_t priority; uint8_t marked; } tag_t;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t packet_switching_random_schedule(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t m_value = input[0], b_value = input[1], t_value = input[2];
    if (m_value < 2 || m_value > MAX_QUEUES || b_value < 1 || b_value > MAX_BUFFER ||
        t_value < 1 || t_value > MAX_SLOTS) return -1;
    const size_t m = (size_t)m_value, b = (size_t)b_value, t = (size_t)t_value;
    const size_t matrix = m * t;
    if (length != 3 + 2 * matrix) return -1;
    for (size_t cell = 0; cell < matrix; ++cell) {
        if (input[3 + cell] < 0 || input[3 + cell] > 1 ||
            input[3 + matrix + cell] < 0 || (uint64_t)input[3 + matrix + cell] > MAX_PRIORITY) return -1;
    }
    size_t load[MAX_QUEUES] = {0}, tag_count[MAX_QUEUES] = {0};
    tag_t tags[MAX_QUEUES][MAX_BUFFER] = {{{0, 0}}};
    int64_t trace[MAX_SLOTS];
    for (size_t slot = 0; slot < t; ++slot) {
        for (size_t q = 0; q < m; ++q) {
            const size_t cell = slot * m + q;
            if (input[3 + cell] == 0 || load[q] == b) continue;
            if (tag_count[q] == b) {
                for (size_t i = 1; i < tag_count[q]; ++i) tags[q][i - 1] = tags[q][i];
                --tag_count[q];
            }
            tags[q][tag_count[q]++] = (tag_t){input[3 + matrix + cell], 0};
            ++load[q];
        }
        size_t best_q = m, best_i = 0;
        int64_t best_priority = -1;
        for (size_t q = 0; q < m; ++q) for (size_t i = 0; i < tag_count[q]; ++i) {
            if (tags[q][i].marked) continue;
            if (best_q == m || tags[q][i].priority > best_priority) {
                best_q = q; best_i = i; best_priority = tags[q][i].priority;
            }
        }
        if (best_q != m) tags[best_q][best_i].marked = 1;
        else {
            best_q = m;
            for (size_t q = 0; q < m; ++q) if (load[q] != 0) { best_q = q; break; }
        }
        if (best_q == m) trace[slot] = -1;
        else { trace[slot] = (int64_t)best_q; --load[best_q]; }
    }
    const size_t output_bytes = 8 * t;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t slot = 0; slot < t; ++slot) store_i64_le(staged, 8 * slot, trace[slot]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
