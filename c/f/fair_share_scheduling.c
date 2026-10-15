#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t position, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t fair_share_scheduling(const int64_t *values, size_t length,
                              uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 3 || length > 323) return -2;
    if (values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 128 ||
        values[2] < 0 || values[2] > 1000000) return -2;
    const size_t user_count = (size_t)values[0];
    const size_t task_count = (size_t)values[1];
    const int64_t resources = values[2];
    if (length != 3 + user_count + 2 * task_count) return -2;

    int64_t ids[64], weights[64];
    size_t order[64];
    for (size_t user = 0; user < user_count; ++user) {
        const int64_t id = values[3 + user];
        if (id < 0 || id > 63) return -2;
        for (size_t previous = 0; previous < user; ++previous)
            if (ids[previous] == id) return -2;
        ids[user] = id;
        weights[user] = 0;
        order[user] = user;
    }
    const size_t task_start = 3 + user_count;
    for (size_t task = 0; task < task_count; ++task) {
        const int64_t owner = values[task_start + 2 * task];
        const int64_t weight = values[task_start + 2 * task + 1];
        if (owner < 0 || owner > 63 || weight < 0 || weight > 1000000) return -2;
        for (size_t user = 0; user < user_count; ++user) {
            if (ids[user] == owner) {
                weights[user] += weight;
                break;
            }
        }
    }
    for (size_t i = 1; i < user_count; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0 && ids[order[j - 1]] > ids[key]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }
    int64_t total_weight = 0;
    for (size_t user = 0; user < user_count; ++user) total_weight += weights[user];
    const size_t required = user_count * 24;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    for (size_t position = 0; position < user_count; ++position) {
        const size_t user = order[position];
        const int64_t allocation = total_weight == 0 ? 0 : weights[user] * resources / total_weight;
        store_i64_le(output, position * 24, ids[user]);
        store_i64_le(output, position * 24 + 8, weights[user]);
        store_i64_le(output, position * 24 + 16, allocation);
    }
    return (int64_t)user_count;
}
