/* Portable greedy bandwidth allocation matching the pinned Java routine. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t bandwidth_allocation(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2) return -1;
    const auto bandwidth = input[0];
    const auto count_value = input[1];
    if (bandwidth < 0 || bandwidth > 100000 || count_value < 0 || count_value > 64) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + 2 * count) return -1;
    for (std::size_t index = 0; index < count; ++index) {
        const auto demand = input[2 + index];
        const auto value = input[2 + count + index];
        if (demand < 1 || demand > 1000 || value < 0 || value > 10000) return -1;
    }

    double ratios[64];
    std::size_t order[64];
    for (std::size_t index = 0; index < count; ++index) {
        ratios[index] = static_cast<double>(input[2 + count + index]) /
                        static_cast<double>(input[2 + index]);
        order[index] = index;
    }
    for (std::size_t index = 1; index < count; ++index) {
        const double key_ratio = ratios[index];
        const std::size_t key_index = order[index];
        std::size_t position = index;
        while (position > 0 && ratios[position - 1] < key_ratio) {
            ratios[position] = ratios[position - 1];
            order[position] = order[position - 1];
            --position;
        }
        ratios[position] = key_ratio;
        order[position] = key_index;
    }

    auto remaining = bandwidth;
    std::int64_t total = 0;
    for (std::size_t position = 0; position < count; ++position) {
        const auto index = order[position];
        const auto demand = input[2 + index];
        const auto value = input[2 + count + index];
        if (remaining >= demand) {
            total += value;
            remaining -= demand;
        } else {
            total += static_cast<std::int64_t>(ratios[position] * static_cast<double>(remaining));
            break;
        }
    }
    return total;
}
