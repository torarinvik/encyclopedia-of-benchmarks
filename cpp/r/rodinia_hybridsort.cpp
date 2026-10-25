/* Rodinia/NVIDIA HybridSort bounded port; complete required notices are in the package LICENSE.txt. */
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t kMaxItems = 64, kBins = 1024;
std::size_t bucket(float value, float minimum, float span) {
    int index = static_cast<int>(((value - minimum) / span) * 1024.0f);
    if (index < 0) index = 0;
    if (index >= static_cast<int>(kBins)) index = static_cast<int>(kBins) - 1;
    return static_cast<std::size_t>(index);
}
void merge_sort(std::int64_t *items, std::int64_t *scratch, std::size_t count) {
    for (std::size_t width = 1; width < count; width *= 2) {
        for (std::size_t left = 0; left < count; left += 2 * width) {
            const auto middle = left + width < count ? left + width : count;
            const auto right = left + 2 * width < count ? left + 2 * width : count;
            auto a = left, b = middle, out = left;
            while (a < middle && b < right) scratch[out++] = items[a] <= items[b] ? items[a++] : items[b++];
            while (a < middle) scratch[out++] = items[a++];
            while (b < right) scratch[out++] = items[b++];
        }
        for (std::size_t i = 0; i < count; ++i) items[i] = scratch[i];
    }
}
void put_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t rodinia_hybridsort(const std::int64_t *input, std::size_t length,
                                            std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > kMaxItems + 1 || input[0] < 2 || input[0] > 64 || length != 1 + static_cast<std::size_t>(input[0])) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    std::int64_t items[kMaxItems], scratch[kMaxItems];
    std::int64_t min_raw = std::numeric_limits<std::int64_t>::max();
    std::int64_t max_raw = std::numeric_limits<std::int64_t>::min();
    for (std::size_t i = 0; i < count; ++i) {
        const auto raw = input[1 + i];
        if (raw < 0 || raw > 1'000'000 || raw % 1000 != 0) return -1;
        items[i] = raw; if (raw < min_raw) min_raw = raw; if (raw > max_raw) max_raw = raw;
    }
    if (min_raw == max_raw) return -1;
    const auto bytes = count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    const float minimum = static_cast<float>(min_raw) / 1'000'000.0f;
    const float maximum = static_cast<float>(max_raw) / 1'000'000.0f;
    const float span = maximum - minimum;
    std::size_t histogram[kBins]{}, offsets[kBins + 1]{}, next[kBins]{};
    std::int64_t scattered[kMaxItems];
    for (std::size_t i = 0; i < count; ++i) ++histogram[bucket(static_cast<float>(items[i]) / 1'000'000.0f, minimum, span)];
    for (std::size_t bin = 0; bin < kBins; ++bin) offsets[bin + 1] = offsets[bin] + histogram[bin];
    for (std::size_t bin = 0; bin < kBins; ++bin) next[bin] = offsets[bin];
    for (std::size_t i = 0; i < count; ++i) {
        const auto bin = bucket(static_cast<float>(items[i]) / 1'000'000.0f, minimum, span);
        scattered[next[bin]++] = items[i];
    }
    for (std::size_t bin = 0; bin < kBins; ++bin) {
        const auto begin = offsets[bin], size = offsets[bin + 1] - begin;
        if (size != 0) merge_sort(scattered + begin, scratch, size);
    }
    for (std::size_t i = 0; i < count; ++i) put_i64(output, 8 * i, scattered[i]);
    return static_cast<std::int64_t>(bytes);
}
