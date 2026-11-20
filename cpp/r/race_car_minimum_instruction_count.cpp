#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t race_car_minimum_instruction_count(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > 2 || length != 1) return -1;
    const auto target_value = input[0];
    if (target_value < 0 || target_value > 127) return -1;
    const auto target = static_cast<std::size_t>(target_value);
    std::array<std::int32_t, 128> distance{};

    for (std::size_t position = 1; position <= target; ++position) {
        std::size_t run = 0;
        std::size_t upper_power = 1;
        while (upper_power <= position) {
            upper_power <<= 1;
            ++run;
        }
        const auto upper = upper_power - 1;
        if (position == upper) {
            distance[position] = static_cast<std::int32_t>(run);
            continue;
        }

        auto best = static_cast<std::int32_t>(run + 1) + distance[upper - position];
        const auto lower = (upper_power >> 1) - 1;
        for (std::size_t backward_run = 0; backward_run + 1 < run; ++backward_run) {
            const auto backward_distance = (std::size_t{1} << backward_run) - 1;
            const auto remaining = position - (lower - backward_distance);
            const auto candidate = static_cast<std::int32_t>(run + backward_run + 1)
                                 + distance[remaining];
            if (candidate < best) best = candidate;
        }
        distance[position] = best;
    }
    return distance[target];
}
