#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8, MAX_INPUT = 18, MAX_Q = 128;
void store_i64(std::uint8_t* out, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[offset + b] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t knapsack_profit_scaling_small_large_fptas(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const std::int64_t cap = input[0], n64 = input[1];
    if (cap < 1 || cap > 30 || n64 < 1 || n64 > static_cast<std::int64_t>(MAX_N) || length != 2 + 2 * static_cast<std::size_t>(n64)) return -1;
    const std::size_t n = static_cast<std::size_t>(n64);
    std::int64_t w[MAX_N]{}, p[MAX_N]{};
    for (std::size_t i = 0; i < n; ++i) { w[i] = input[2 + 2 * i]; p[i] = input[3 + 2 * i]; if (w[i] < 1 || w[i] > 30 || p[i] < 1 || p[i] > 100) return -1; }
    if (output == nullptr || capacity < 16) return -2;
    std::size_t order[MAX_N]{}, eligible = 0;
    for (std::size_t i = 0; i < n; ++i) if (w[i] <= cap) order[eligible++] = i;
    for (std::size_t i = 1; i < eligible; ++i) { const auto key = order[i]; std::size_t j = i; while (j && p[key] * w[order[j - 1]] > p[order[j - 1]] * w[key]) { order[j] = order[j - 1]; --j; } order[j] = key; }
    std::int64_t upper_num = 0, upper_den = 1, room = cap;
    for (std::size_t k = 0; k < eligible; ++k) { const auto i = order[k]; if (w[i] <= room) { upper_num += p[i]; room -= w[i]; } else { upper_num = upper_num * w[i] + p[i] * room; upper_den = w[i]; break; } }
    std::size_t small[MAX_N]{}, large[MAX_N]{}, ns = 0, nl = 0;
    for (std::size_t i = 0; i < n; ++i) if (w[i] <= cap) { if (4 * p[i] * upper_den <= upper_num) small[ns++] = i; else large[nl++] = i; }
    for (std::size_t i = 1; i < ns; ++i) { const auto key = small[i]; std::size_t j = i; while (j && p[key] * w[small[j - 1]] > p[small[j - 1]] * w[key]) { small[j] = small[j - 1]; --j; } small[j] = key; }
    std::int64_t dpw[MAX_Q + 1], dpm[MAX_Q + 1]{};
    for (auto& x : dpw) x = cap + 1;
    dpw[0] = 0; std::size_t reachable = 0;
    for (std::size_t k = 0; k < nl; ++k) { const auto i = large[k]; const std::size_t v = upper_num ? static_cast<std::size_t>(16 * p[i] * upper_den / upper_num) : 0; for (std::size_t q = reachable + 1; q > 0;) { --q; if (dpw[q] <= cap) { const auto d = q + v; const auto nw = dpw[q] + w[i], nm = dpm[q] | (std::int64_t{1} << i); if (nw < dpw[d] || (nw == dpw[d] && nm < dpm[d])) { dpw[d] = nw; dpm[d] = nm; } } } reachable += v; }
    std::int64_t best_mask = 0, best_profit = 0;
    for (std::size_t q = 0; q <= reachable; ++q) if (dpw[q] <= cap) { auto mask = dpm[q]; std::int64_t value = 0, remaining = cap - dpw[q]; for (std::size_t i = 0; i < n; ++i) if ((static_cast<std::uint64_t>(mask) >> i) & 1U) value += p[i]; for (std::size_t k = 0; k < ns; ++k) { const auto i = small[k]; if (w[i] <= remaining) { remaining -= w[i]; mask |= std::int64_t{1} << i; value += p[i]; } } if (value > best_profit || (value == best_profit && mask < best_mask)) { best_profit = value; best_mask = mask; } }
    store_i64(output, 0, best_mask); store_i64(output, 8, best_profit); return 16;
}
