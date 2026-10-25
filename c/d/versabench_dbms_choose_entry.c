#include <stddef.h>
#include <stdint.h>

#define MAX_CHILDREN 8
#define MAX_INPUT_LENGTH (1 + 8 * MAX_CHILDREN + 8)

static int valid_box(const int64_t *v, size_t at) {
    for (size_t d = 0; d < 4; ++d)
        if (v[at + d] < -8 || v[at + d] > 8 || v[at + 4 + d] < -8 ||
            v[at + 4 + d] > 8 || v[at + d] >= v[at + 4 + d]) return 0;
    return 1;
}

static int64_t volume_at(const int64_t *v, size_t at) {
    int64_t result = 1;
    for (size_t d = 0; d < 4; ++d) result *= v[at + 4 + d] - v[at + d];
    return result;
}

static int64_t penalty_at(const int64_t *v, size_t child, size_t incoming) {
    int64_t joined_volume = 1;
    for (size_t d = 0; d < 4; ++d) {
        const int64_t child_lo = v[child + d], incoming_lo = v[incoming + d];
        const int64_t child_hi = v[child + 4 + d], incoming_hi = v[incoming + 4 + d];
        const int64_t lo = child_lo < incoming_lo ? child_lo : incoming_lo;
        const int64_t hi = child_hi > incoming_hi ? child_hi : incoming_hi;
        joined_volume *= hi - lo;
    }
    return joined_volume - volume_at(v, child);
}

int64_t versabench_dbms_choose_entry(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH + 1) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 1 || raw_count > MAX_CHILDREN) return -1;
    const size_t count = (size_t)raw_count;
    if (length != 1 + 8 * count + 8) return -1;
    const size_t incoming = 1 + 8 * count;
    for (size_t i = 0; i < count; ++i) if (!valid_box(values, 1 + 8 * i)) return -1;
    if (!valid_box(values, incoming)) return -1;
    size_t best = 0;
    int64_t best_penalty = penalty_at(values, 1, incoming);
    for (size_t i = 1; i < count; ++i) {
        const int64_t candidate = penalty_at(values, 1 + 8 * i, incoming);
        if (candidate < best_penalty) { best = i; best_penalty = candidate; }
    }
    return (int64_t)best;
}
