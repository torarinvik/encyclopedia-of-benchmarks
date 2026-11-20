#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>

namespace {
constexpr std::size_t max_n = 256;
constexpr std::size_t max_parseable_length = 258;
}

extern "C" std::int64_t erdos_gallai_graphical_sequence(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const std::int64_t n_word = input[0];
    if (n_word < 0 || n_word > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(n_word);
    if (length != n + 1) return -1;

    std::array<std::int64_t, max_n> degrees{};
    std::array<std::int64_t, max_n + 1> prefix{};
    std::int64_t sum = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t degree = input[i + 1];
        if (degree < 0 || degree >= n_word) return -1;
        degrees[i] = degree;
        sum += degree;
    }
    if ((sum & 1) != 0) return 0;
    if (n == 0) return 1;

    std::sort(degrees.begin(), degrees.begin() + n,
              std::greater<std::int64_t>());
    for (std::size_t i = 0; i < n; ++i) prefix[i + 1] = prefix[i] + degrees[i];

    for (std::size_t k = 1; k <= n; ++k) {
        std::size_t low = k, high = n;
        while (low < high) {
            const std::size_t mid = low + (high - low) / 2;
            if (degrees[mid] >= static_cast<std::int64_t>(k)) low = mid + 1;
            else high = mid;
        }
        const std::size_t split = low;
        const std::int64_t rhs = static_cast<std::int64_t>(k) * static_cast<std::int64_t>(k - 1)
                               + static_cast<std::int64_t>(split - k) * static_cast<std::int64_t>(k)
                               + (prefix[n] - prefix[split]);
        if (prefix[k] > rhs) return 0;
    }
    return 1;
}
