#include <cstddef>
#include <cstdint>

extern "C" std::int64_t k_folds(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1;
    const auto sample_count = values[0], fold_count = values[1];
    if (sample_count < 1 || sample_count > 12 || fold_count < 1 || fold_count > 12) return -1;
    const auto width = (sample_count + fold_count - 1) / fold_count;
    std::uint64_t result = static_cast<std::uint64_t>(sample_count) << 48;
    for (std::int64_t index = 0; index < sample_count; ++index) {
        const auto fold = static_cast<std::uint64_t>(index + width) / static_cast<std::uint64_t>(width);
        result |= fold << (4 * static_cast<unsigned>(index));
    }
    return static_cast<std::int64_t>(result);
}
