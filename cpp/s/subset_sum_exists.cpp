/* Decide whether a signed integer subset reaches the requested sum. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t subset_sum_exists(const std::int64_t *input,
                                           std::size_t length) noexcept
{
    if (length == 0 || length > 25) return -1;
    const auto target = input[0];
    if (target < -6144 || target > 6144) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (input[index] < -256 || input[index] > 256) return -1;

    bool reachable[12289]{};
    reachable[6144] = true;
    std::int64_t low = 0, high = 0;
    for (std::size_t index = 1; index < length; ++index) {
        const auto value = input[index];
        if (value > 0) {
            for (auto sum = high; sum >= low; --sum)
                if (reachable[static_cast<std::size_t>(sum + 6144)])
                    reachable[static_cast<std::size_t>(sum + value + 6144)] = true;
            high += value;
        } else if (value < 0) {
            for (auto sum = low; sum <= high; ++sum)
                if (reachable[static_cast<std::size_t>(sum + 6144)])
                    reachable[static_cast<std::size_t>(sum + value + 6144)] = true;
            low += value;
        }
    }
    return reachable[static_cast<std::size_t>(target + 6144)] ? 1 : 0;
}
