#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_jobs = 32; constexpr std::size_t max_input_length = 1 + 3 * max_jobs + 1; constexpr std::int64_t max_profit = 1'000'000; }

extern "C" std::int64_t job_sequencing(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > max_input_length || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_jobs)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3 * n) return -1;
    bool seen[128]{}; std::int64_t previous_profit = max_profit + 1;
    for (std::size_t i = 0; i < n; ++i) {
        const auto id = input[1 + 3 * i], deadline = input[2 + 3 * i], profit = input[3 + 3 * i];
        const bool letter = (id >= 'A' && id <= 'Z') || (id >= 'a' && id <= 'z');
        if (!letter || seen[id] || deadline < 1 || deadline > static_cast<std::int64_t>(n) || profit < 1 || profit > max_profit || profit >= previous_profit) return -1;
        seen[id] = true; previous_profit = profit;
    }
    std::uint8_t slots[max_jobs]{}; std::int64_t total_profit = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto deadline = static_cast<std::size_t>(input[2 + 3 * i]);
        for (std::size_t remaining = deadline; remaining > 0; --remaining) {
            const auto slot = remaining - 1;
            if (slots[slot] == 0) { slots[slot] = static_cast<std::uint8_t>(input[1 + 3 * i]); total_profit += input[3 + 3 * i]; break; }
        }
    }
    std::size_t count = 0; for (std::size_t i = 0; i < n; ++i) if (slots[i] != 0) ++count;
    const std::size_t required = 9 + count; if (output == nullptr || capacity < required) return -2;
    output[0] = static_cast<std::uint8_t>(count); const auto profit_bits = static_cast<std::uint64_t>(total_profit);
    for (std::size_t i = 0; i < 8; ++i) output[1 + i] = static_cast<std::uint8_t>(profit_bits >> (8 * i));
    std::size_t written = 9; for (std::size_t i = 0; i < n; ++i) if (slots[i] != 0) output[written++] = slots[i];
    return static_cast<std::int64_t>(required);
}
