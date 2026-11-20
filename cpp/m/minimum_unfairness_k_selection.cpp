#include <array>
#include <utility>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::int64_t min_value = -1'000'000'000;
constexpr std::int64_t max_value = 1'000'000'000;

void sift_down(std::array<std::int64_t, max_n>& values, std::size_t root, std::size_t end) noexcept
{
    while (root < end / 2) {
        auto child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        std::swap(values[root], values[child]);
        root = child;
    }
}

void heap_sort(std::array<std::int64_t, max_n>& values, std::size_t length) noexcept
{
    for (auto start = length / 2; start > 0; --start) sift_down(values, start - 1, length);
    for (auto end = length; end > 1; --end) {
        std::swap(values[0], values[end - 1]);
        sift_down(values, 0, end - 1);
    }
}
} // namespace

extern "C" std::int64_t minimum_unfairness_k_selection(const std::int64_t* packed,
                                                        std::size_t length) noexcept
{
    if (packed == nullptr || length < 4 || length > max_n + 2) return -1;
    const auto n_value = packed[0];
    const auto k_value = packed[1];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n)
        || k_value < 2 || k_value > n_value
        || length != static_cast<std::size_t>(n_value) + 2) return -1;

    const auto n = static_cast<std::size_t>(n_value);
    const auto k = static_cast<std::size_t>(k_value);
    std::array<std::int64_t, max_n> sorted{};
    for (std::size_t index = 0; index < n; ++index) {
        const auto value = packed[index + 2];
        if (value < min_value || value > max_value) return -1;
        sorted[index] = value;
    }
    heap_sort(sorted, n);

    std::int64_t best = 2'000'000'001;
    for (std::size_t first = 0; first + k <= n; ++first) {
        const auto width = sorted[first + k - 1] - sorted[first];
        if (width < best) best = width;
    }
    return best;
}
