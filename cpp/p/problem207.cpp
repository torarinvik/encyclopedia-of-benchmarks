#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double MIN_PROPORTION = 1.0e-5;
constexpr double MAX_PROPORTION = 1.0;
constexpr std::int64_t MAX_PARTITIONS = 5'000'000;

bool is_power_of_two(std::int64_t value) noexcept
{
    return value > 0 && (value & (value - 1)) == 0;
}
}

extern "C" double problem207(double max_proportion) noexcept
{
    if (max_proportion != max_proportion || max_proportion < MIN_PROPORTION ||
        max_proportion > MAX_PROPORTION) return INVALID_RESULT;
    std::int64_t partitions = 0;
    std::int64_t perfect_partitions = 0;
    while (partitions < MAX_PARTITIONS) {
        ++partitions;
        const std::int64_t candidate = partitions * (partitions + 1);
        if (is_power_of_two(partitions + 1)) ++perfect_partitions;
        if (static_cast<double>(perfect_partitions) / static_cast<double>(partitions) < max_proportion)
            return static_cast<double>(candidate);
    }
    return INVALID_RESULT;
}
