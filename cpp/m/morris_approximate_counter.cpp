#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxUpdates = 53;
constexpr std::size_t kDrawBits = 53;
constexpr std::size_t kMaxInputValues = 1 + kMaxUpdates;
constexpr std::uint64_t kDrawLimit = std::uint64_t{1} << kDrawBits;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t morris_approximate_counter(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInputValues) return -1;
    const auto updates_value = input[0];
    if (updates_value < 1 || updates_value > 53) return -1;
    const auto updates = static_cast<std::size_t>(updates_value);
    if (length != 1 + updates) return -1;

    std::size_t state = 0;
    for (std::size_t event = 0; event < updates; ++event) {
        const auto draw_value = input[1 + event];
        if (draw_value < 0 || static_cast<std::uint64_t>(draw_value) >= kDrawLimit) return -1;
        const auto threshold = std::uint64_t{1} << (kDrawBits - state);
        if (static_cast<std::uint64_t>(draw_value) < threshold) ++state;
    }

    if (output == nullptr || capacity < 16) return -2;
    const auto estimate = static_cast<std::int64_t>((std::uint64_t{1} << state) - 1);
    store_i64_le(output, 0, static_cast<std::int64_t>(state));
    store_i64_le(output, 8, estimate);
    return 16;
}
