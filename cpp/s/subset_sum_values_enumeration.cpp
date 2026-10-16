/* Enumerate positive value lists in include-first source order. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxItems = 11;
constexpr std::int64_t kMaxTarget = 256;
constexpr std::int64_t kMaxItem = 64;

void write_i64_le(std::uint8_t *output, std::size_t &position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8)
        output[position++] = static_cast<std::uint8_t>((bits >> shift) & 0xffu);
}

std::size_t enumerate(const std::int64_t *items, std::size_t item_count, std::size_t index,
                      std::int64_t target, std::int64_t sum, std::int64_t *chosen,
                      std::size_t chosen_count, std::uint8_t *output,
                      std::size_t *position, bool emit) noexcept {
    if (sum == target) {
        if (emit) {
            write_i64_le(output, *position, static_cast<std::int64_t>(chosen_count));
            for (std::size_t i = 0; i < chosen_count; ++i) write_i64_le(output, *position, chosen[i]);
        }
        return chosen_count + 1;
    }
    if (index == item_count || sum > target) return 0;
    chosen[chosen_count] = items[index];
    const auto include_slots = enumerate(items, item_count, index + 1, target,
        sum + items[index], chosen, chosen_count + 1, output, position, emit);
    const auto exclude_slots = enumerate(items, item_count, index + 1, target,
        sum, chosen, chosen_count, output, position, emit);
    return include_slots + exclude_slots;
}
}

extern "C" std::int64_t subset_sum_values_enumeration(const std::int64_t *input,
                                                       std::size_t length,
                                                       std::uint8_t *output,
                                                       std::size_t output_capacity) noexcept {
    if (input == nullptr || length == 0 || length > kMaxItems + 1) return -1;
    const auto target = input[0];
    if (target < 0 || target > kMaxTarget) return -1;
    const auto items = length - 1;
    for (std::size_t i = 0; i < items; ++i)
        if (input[i + 1] < 1 || input[i + 1] > kMaxItem) return -1;

    std::int64_t chosen[kMaxItems]{};
    std::size_t dummy_position = 0;
    const auto slots = enumerate(input + 1, items, 0, target, 0, chosen, 0,
                                 nullptr, &dummy_position, false);
    const auto required = slots * 8;
    if (required == 0) return 0;
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    enumerate(input + 1, items, 0, target, 0, chosen, 0, output, &position, true);
    return static_cast<std::int64_t>(position);
}
