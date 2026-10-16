#include <cstdint>
#include <vector>

extern "C" std::int64_t problem95(std::int64_t limit) noexcept {
    if (limit < 1 || limit > 1'000'000) return -1;
    constexpr std::uint32_t mark = 0x80000000u, mask = 0x7fffffffu;
    std::vector<std::uint32_t> sums(static_cast<std::size_t>(limit) + 1, 0);
    for (std::int64_t divisor = 1; divisor <= limit / 2; ++divisor)
        for (std::int64_t multiple = 2 * divisor; multiple <= limit; multiple += divisor)
            sums[static_cast<std::size_t>(multiple)] += static_cast<std::uint32_t>(divisor);
    std::int64_t best_length = 0, answer = 0;
    for (std::int64_t start = 2; start <= limit; ++start) {
        auto current = sums[static_cast<std::size_t>(start)];
        std::int64_t length = 1;
        sums[static_cast<std::size_t>(start)] |= mark;
        while (current > 1 && current <= static_cast<std::uint32_t>(limit) && (sums[current] & mark) == 0) {
            sums[current] |= mark;
            current = sums[current] & mask;
            ++length;
        }
        if (current == static_cast<std::uint32_t>(start) && length > best_length) { best_length = length; answer = start; }
        current = static_cast<std::uint32_t>(start);
        for (std::int64_t step = 0; step < length; ++step) { auto next = sums[current] & mask; sums[current] = next; current = next; }
    }
    return answer;
}
