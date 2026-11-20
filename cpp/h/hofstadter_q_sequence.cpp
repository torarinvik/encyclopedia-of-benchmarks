#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_index = 128;
constexpr std::size_t max_parseable_length = 2;
}

extern "C" std::int64_t hofstadter_q_sequence(const std::int64_t* input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_index)) return -1;

    const auto target = static_cast<std::size_t>(input[0]);
    std::array<std::int64_t, max_index + 1> q{};
    q[1] = 1;
    if (target >= 2) q[2] = 1;
    for (std::size_t n = 3; n <= target; ++n) {
        const auto left = static_cast<std::int64_t>(n) - q[n - 1];
        const auto right = static_cast<std::int64_t>(n) - q[n - 2];
        if (left < 1 || right < 1 || left >= static_cast<std::int64_t>(n)
                || right >= static_cast<std::int64_t>(n)) return -1;
        q[n] = q[static_cast<std::size_t>(left)] + q[static_cast<std::size_t>(right)];
    }
    return q[target];
}
