#include <cstddef>
#include <cstdint>

static void store_i64_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

extern "C" std::int64_t fair_share_scheduling(const std::int64_t *values, std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 3 || length > 323) return -2;
    if (values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 128 ||
        values[2] < 0 || values[2] > 1000000) return -2;
    const auto user_count = static_cast<std::size_t>(values[0]);
    const auto task_count = static_cast<std::size_t>(values[1]);
    const auto resources = values[2];
    if (length != 3 + user_count + 2 * task_count) return -2;

    std::int64_t ids[64], weights[64];
    std::size_t order[64];
    for (std::size_t user = 0; user < user_count; ++user) {
        const auto id = values[3 + user];
        if (id < 0 || id > 63) return -2;
        for (std::size_t previous = 0; previous < user; ++previous)
            if (ids[previous] == id) return -2;
        ids[user] = id;
        weights[user] = 0;
        order[user] = user;
    }
    const auto task_start = 3 + user_count;
    for (std::size_t task = 0; task < task_count; ++task) {
        const auto owner = values[task_start + 2 * task];
        const auto weight = values[task_start + 2 * task + 1];
        if (owner < 0 || owner > 63 || weight < 0 || weight > 1000000) return -2;
        for (std::size_t user = 0; user < user_count; ++user) {
            if (ids[user] == owner) {
                weights[user] += weight;
                break;
            }
        }
    }
    for (std::size_t i = 1; i < user_count; ++i) {
        const auto key = order[i];
        auto j = i;
        while (j > 0 && ids[order[j - 1]] > ids[key]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = key;
    }
    std::int64_t total_weight = 0;
    for (std::size_t user = 0; user < user_count; ++user) total_weight += weights[user];
    const auto required = user_count * 24;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;
    for (std::size_t position = 0; position < user_count; ++position) {
        const auto user = order[position];
        const auto allocation = total_weight == 0 ? 0 : weights[user] * resources / total_weight;
        store_i64_le(output, position * 24, ids[user]);
        store_i64_le(output, position * 24 + 8, weights[user]);
        store_i64_le(output, position * 24 + 16, allocation);
    }
    return static_cast<std::int64_t>(user_count);
}
