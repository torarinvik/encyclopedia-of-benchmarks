#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxUpdates = 30;
constexpr std::size_t kMaxValidInputValues = 1 + kMaxUpdates;
constexpr std::size_t kMaxParseableInputValues = kMaxValidInputValues + 1;
constexpr std::uint64_t kDrawSpace = UINT64_C(205891132094649);

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t morris_approximate_counter_base_three(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxParseableInputValues)
        return -1;
    const auto updates_value = input[0];
    if (updates_value < 0 || updates_value > static_cast<std::int64_t>(kMaxUpdates))
        return -1;
    const auto updates = static_cast<std::size_t>(updates_value);
    if (length != 1 + updates) return -1;

    std::size_t state = 0;
    std::uint64_t threshold = kDrawSpace;
    std::uint64_t estimate = 0;
    for (std::size_t event = 0; event < updates; ++event) {
        const auto draw_value = input[1 + event];
        if (draw_value < 0 || static_cast<std::uint64_t>(draw_value) >= kDrawSpace)
            return -1;
        if (static_cast<std::uint64_t>(draw_value) < threshold) {
            ++state;
            threshold /= 3;
            estimate = 3 * estimate + 1;
        }
    }

    if (output == nullptr || capacity < 16) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(state));
    store_i64_le(output, 8, static_cast<std::int64_t>(estimate));
    return 16;
}
