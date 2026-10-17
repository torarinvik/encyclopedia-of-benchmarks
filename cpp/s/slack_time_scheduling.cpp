#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MAX_N = 64; constexpr std::int64_t MAX_TIME = 1000000; }

extern "C" std::int64_t slack_time_scheduling(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > 1 + 2 * MAX_N) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    std::int64_t slack[MAX_N]{};
    std::size_t order[MAX_N]{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto execution = input[1 + 2 * i], deadline = input[2 + 2 * i];
        if (execution < 0 || execution > MAX_TIME || deadline < 0 || deadline > MAX_TIME) return -1;
        slack[i] = deadline - execution;
        order[i] = i;
    }
    const std::size_t bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 1; i < n; ++i) {
        const auto key = order[i];
        auto j = i;
        while (j > 0 && slack[key] < slack[order[j - 1]]) { order[j] = order[j - 1]; --j; }
        order[j] = key;
    }
    for (std::size_t i = 0; i < n; ++i) {
        std::uint64_t bits = order[i];
        for (std::size_t b = 0; b < 8; ++b) { output[i * 8 + b] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
    }
    return static_cast<std::int64_t>(bytes);
}
