#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 128;
constexpr std::size_t kMaxK = 512;
constexpr std::int64_t kModulus = 1'000'000'007;
}

extern "C" std::int64_t k_inverse_pairs_array(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 3 || length != 2) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxN)
        || input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxK)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto k = static_cast<std::size_t>(input[1]);
    if (k > n * (n == 0 ? 0 : n - 1) / 2) return 0;

    std::array<std::int64_t, kMaxK + 1> previous{};
    std::array<std::int64_t, kMaxK + 1> current{};
    previous[0] = 1;
    for (std::size_t size = 1; size <= n; ++size) {
        std::int64_t window = 0;
        for (std::size_t inversions = 0; inversions <= k; ++inversions) {
            window += previous[inversions];
            if (inversions >= size) window -= previous[inversions - size];
            window %= kModulus;
            if (window < 0) window += kModulus;
            current[inversions] = window;
        }
        previous = current;
        current.fill(0);
    }
    return previous[k];
}
