/* Find the cycle entrance induced by the duplicate value. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t find_duplicate_number(const std::int64_t *values,
                                               std::size_t length) noexcept
{
    if (length < 2 || length > 100001) return -1;
    const auto maximum_value = length - 1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 1 || static_cast<std::uint64_t>(values[index]) > maximum_value) return -1;
    }

    auto slow = static_cast<std::size_t>(values[0]);
    auto fast = slow;
    do {
        slow = static_cast<std::size_t>(values[slow]);
        fast = static_cast<std::size_t>(values[static_cast<std::size_t>(values[fast])]);
    } while (slow != fast);

    slow = static_cast<std::size_t>(values[0]);
    while (slow != fast) {
        slow = static_cast<std::size_t>(values[slow]);
        fast = static_cast<std::size_t>(values[fast]);
    }
    return static_cast<std::int64_t>(slow);
}
