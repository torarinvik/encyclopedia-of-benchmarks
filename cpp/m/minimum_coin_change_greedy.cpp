#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MIN_TARGET = -4096;
constexpr std::int64_t MAX_TARGET = 4096;
constexpr std::size_t MAX_DENOMINATIONS = 32;
constexpr std::size_t MAX_INPUT_VALUES = 2 + MAX_DENOMINATIONS;
constexpr std::size_t MAX_OUTPUT_BYTES = (1 + MAX_TARGET) * 4;

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t minimum_coin_change_greedy(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const auto target = input[0];
    const auto count_value = input[1];
    if (target < MIN_TARGET || target > MAX_TARGET ||
        count_value < 0 || count_value > static_cast<std::int64_t>(MAX_DENOMINATIONS)) return -1;
    const auto denomination_count = static_cast<std::size_t>(count_value);
    if (length != 2 + denomination_count) return -1;

    std::int32_t denominations[MAX_DENOMINATIONS]{};
    std::int64_t previous = 0;
    for (std::size_t index = 0; index < denomination_count; ++index) {
        const auto denomination = input[2 + index];
        if (denomination < 1 || denomination > 4096 || denomination <= previous) return -1;
        denominations[index] = static_cast<std::int32_t>(denomination);
        previous = denomination;
    }

    std::int32_t chosen[4096]{};
    std::size_t chosen_count = 0;
    if (target > 0) {
        auto remaining = target;
        for (std::size_t index = denomination_count; index > 0; --index) {
            const auto denomination = denominations[index - 1];
            while (remaining >= denomination) {
                remaining -= denomination;
                chosen[chosen_count++] = denomination;
            }
        }
    }

    const auto needed = (1 + chosen_count) * 4;
    if (output == nullptr || capacity < needed) return -2;
    write_i32_le(output, 0, static_cast<std::int32_t>(chosen_count));
    for (std::size_t index = 0; index < chosen_count; ++index)
        write_i32_le(output, 4 + 4 * index, chosen[index]);
    return static_cast<std::int64_t>(needed);
}
