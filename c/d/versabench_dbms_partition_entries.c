#include <stddef.h>
#include <stdint.h>

#define MAX_FAN 8
#define MAX_INPUT_LENGTH (1 + 8 * (MAX_FAN + 1))

static int valid_box(const int64_t *v, size_t at) {
    for (size_t d = 0; d < 4; ++d)
        if (v[at + d] < -8 || v[at + d] > 8 || v[at + 4 + d] < -8 || v[at + 4 + d] > 8 || v[at + d] >= v[at + 4 + d]) return 0;
    return 1;
}
static int64_t volume_at(const int64_t *v, size_t at) {
    int64_t product = 1;
    for (size_t d = 0; d < 4; ++d) product *= v[at + 4 + d] - v[at + d];
    return product;
}
static int64_t union_volume(const int64_t *v, size_t left, size_t right) {
    int64_t product = 1;
    for (size_t d = 0; d < 4; ++d) {
        int64_t lo = v[left + d] < v[right + d] ? v[left + d] : v[right + d];
        int64_t left_hi = v[left + 4 + d], right_hi = v[right + 4 + d];
        int64_t hi = left_hi > right_hi ? left_hi : right_hi;
        product *= hi - lo;
    }
    return product;
}
static int64_t penalty(const int64_t *v, size_t seed, size_t entry) {
    return union_volume(v, seed, entry) - volume_at(v, seed);
}

int64_t versabench_dbms_partition_entries(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH + 1) return -1;
    const int64_t raw_fan = values[0];
    if (raw_fan < 2 || raw_fan > MAX_FAN) return -1;
    const size_t fan = (size_t)raw_fan, count = fan + 1;
    if (length != 1 + 8 * count) return -1;
    for (size_t i = 0; i < count; ++i) if (!valid_box(values, 1 + 8 * i)) return -1;

    size_t seed_a = 0, seed_b = 1;
    int64_t largest = union_volume(values, 1, 9);
    for (size_t i = 0; i < count; ++i) for (size_t j = i + 1; j < count; ++j) {
        int64_t candidate = union_volume(values, 1 + 8 * i, 1 + 8 * j);
        if (candidate > largest) { largest = candidate; seed_a = i; seed_b = j; }
    }
    const size_t seed_a_at = 1 + 8 * seed_a, seed_b_at = 1 + 8 * seed_b;
    size_t size_a = 1, size_b = 1;
    int64_t mask = (int64_t)1 << seed_a;
    for (size_t i = 0; i < count; ++i) {
        if (i == seed_a || i == seed_b) continue;
        const size_t at = 1 + 8 * i;
        if (size_a < fan && size_b < fan) {
            if (penalty(values, seed_a_at, at) < penalty(values, seed_b_at, at)) {
                mask |= (int64_t)1 << i;
                ++size_a;
            } else ++size_b;
        } else if (size_a >= fan && size_b < fan) ++size_b;
        else if (size_b >= fan && size_a < fan) { mask |= (int64_t)1 << i; ++size_a; }
        else return -1;
    }
    return mask;
}
