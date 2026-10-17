#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_values = 131;
constexpr std::int64_t max_validators = 128;
constexpr std::int64_t max_stake = 1'000'000;
constexpr std::int64_t max_total_stake = 128'000'000;
}

extern "C" std::int64_t roulette_wheel_selection(const std::int64_t *input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_input_values) return -1;

    const auto count_value = input[0];
    if (count_value < 1 || count_value > max_validators) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return -1;

    std::int64_t total = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto stake = input[1 + index];
        if (stake < 1 || stake > max_stake) return -1;
        if (total > max_total_stake - stake) return -1;
        total += stake;
    }

    const auto ticket = input[1 + count];
    if (ticket < 0 || ticket >= total) return -1;

    std::int64_t cumulative = 0;
    for (std::size_t index = 0; index < count; ++index) {
        cumulative += input[1 + index];
        if (ticket < cumulative) return static_cast<std::int64_t>(index) + 1;
    }
    return -1;
}
