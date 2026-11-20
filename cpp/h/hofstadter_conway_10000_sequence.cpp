#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_index = 8192;
constexpr std::size_t max_parseable_length = 2;
}

extern "C" std::int64_t hofstadter_conway_10000_sequence(const std::int64_t* input,
                                                           std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || input[0] < 2 || input[0] > static_cast<std::int64_t>(max_index)) return -1;

    const auto target = static_cast<std::size_t>(input[0]);
    std::array<std::int64_t, max_index + 1> a{};
    a[1] = 1;
    a[2] = 1;
    for (std::size_t n = 3; n <= target; ++n) {
        const auto previous = a[n - 1];
        const auto other = static_cast<std::int64_t>(n) - previous;
        if (previous < 1 || previous >= static_cast<std::int64_t>(n)
                || other < 1 || other >= static_cast<std::int64_t>(n)) return -1;
        a[n] = a[static_cast<std::size_t>(previous)] + a[static_cast<std::size_t>(other)];
    }
    return a[target];
}
