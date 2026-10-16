#include <array>
#include <cstdint>

extern "C" std::int64_t problem10(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 2'000'000) return -1;
    std::array<bool, 1'000'000> composite{};
    const std::int64_t odd_count = limit / 2;
    std::int64_t sum = limit > 2 ? 2 : 0;
    for (std::int64_t prime = 3; prime * prime < limit; prime += 2) {
        if (!composite[static_cast<std::size_t>(prime / 2)]) {
            for (std::int64_t index = prime * prime / 2; index < odd_count; index += prime)
                composite[static_cast<std::size_t>(index)] = true;
        }
    }
    for (std::int64_t index = 1; index < odd_count; ++index)
        if (!composite[static_cast<std::size_t>(index)]) sum += 2 * index + 1;
    return sum;
}
