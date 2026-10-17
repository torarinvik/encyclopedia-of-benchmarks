#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t subset_count(const std::int64_t *values,
                                      std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 33) return -1;

    const std::int64_t count_value = values[0];
    const std::int64_t target = values[1];
    if (count_value < 1 || count_value > 30 || target < 0 || target > 64 ||
        length != static_cast<std::size_t>(count_value) + 2) return -1;

    for (std::int64_t index = 0; index < count_value; ++index) {
        const std::int64_t value = values[static_cast<std::size_t>(index) + 2];
        if (value < 0 || value > 64) return -1;
    }

    std::array<std::int64_t, 65> previous{};
    previous[0] = 1;
    if (values[2] <= target) previous[static_cast<std::size_t>(values[2])] = 1;

    for (std::int64_t index = 1; index < count_value; ++index) {
        std::array<std::int64_t, 65> current{};
        current[0] = 1;
        for (std::int64_t amount = 1; amount <= target; ++amount) {
            const std::int64_t not_taken = previous[static_cast<std::size_t>(amount)];
            const std::int64_t value = values[static_cast<std::size_t>(index) + 2];
            const std::int64_t taken =
                value <= amount ? previous[static_cast<std::size_t>(amount - value)] : 0;
            current[static_cast<std::size_t>(amount)] = not_taken + taken;
        }
        previous = current;
    }
    return previous[static_cast<std::size_t>(target)];
}
