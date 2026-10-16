#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t maximum_sum_bst(const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::size_t max_slots = 31;
    constexpr std::int64_t max_value = 1'000'000, empty_min = 1'000'001;
    if (input == nullptr || length < 1 || length > max_slots + 1) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_slots) || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 1] < -1 || input[i + 1] > max_value) return -1;
        if (input[i + 1] != -1 && i > 0 && input[(i - 1) / 2 + 1] == -1) return -1;
    }
    if (count == 0) return 0;
    std::array<bool, max_slots> valid{};
    std::array<std::int64_t, max_slots> minimum{}, maximum{}, sum{}, best{};
    for (std::size_t remaining = count; remaining > 0; --remaining) {
        const std::size_t i = remaining - 1;
        if (input[i + 1] == -1) { valid[i] = true; minimum[i] = empty_min; maximum[i] = -1; continue; }
        const std::size_t left = 2 * i + 1, right = left + 1;
        const bool lv = left >= count || valid[left], rv = right >= count || valid[right];
        const auto lmax = left >= count ? -1 : maximum[left];
        const auto rmin = right >= count ? empty_min : minimum[right];
        const auto lmin = left >= count ? empty_min : minimum[left];
        const auto rmax = right >= count ? -1 : maximum[right];
        const auto lsum = left >= count ? 0 : sum[left], rsum = right >= count ? 0 : sum[right];
        const auto lb = left >= count ? 0 : best[left], rb = right >= count ? 0 : best[right];
        const auto value = input[i + 1];
        if (lv && rv && lmax < value && value < rmin) {
            valid[i] = true; minimum[i] = lmin < value ? lmin : value; maximum[i] = rmax > value ? rmax : value;
            sum[i] = lsum + rsum + value; best[i] = sum[i] > lb ? sum[i] : lb; if (rb > best[i]) best[i] = rb;
        } else { valid[i] = false; best[i] = lb > rb ? lb : rb; }
    }
    return best[0];
}
