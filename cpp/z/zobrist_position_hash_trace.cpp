#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kSlots = 16;
constexpr std::size_t kFeatures = 3;
constexpr std::size_t kMaxOperations = 64;
constexpr std::size_t kBaseWords = 1 + kSlots * kFeatures + kSlots;
constexpr std::size_t kMaxWords = kBaseWords + 2 * kMaxOperations;

void store_hash(std::uint8_t *output, std::size_t offset, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
}

extern "C" std::int64_t zobrist_position_hash_trace(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < kBaseWords || length > kMaxWords + 1) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(kMaxOperations)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != kBaseWords + 2 * count) return -1;

    for (std::size_t i = 0; i < kSlots * kFeatures; ++i)
        if (input[1 + i] < 0) return -1;
    const std::size_t state_start = 1 + kSlots * kFeatures;
    for (std::size_t slot = 0; slot < kSlots; ++slot)
        if (input[state_start + slot] < 0 || input[state_start + slot] > kFeatures) return -1;
    const std::size_t edits_start = state_start + kSlots;
    for (std::size_t edit = 0; edit < count; ++edit) {
        const auto slot = input[edits_start + 2 * edit];
        const auto feature = input[edits_start + 2 * edit + 1];
        if (slot < 0 || slot >= static_cast<std::int64_t>(kSlots) ||
            feature < 0 || feature > static_cast<std::int64_t>(kFeatures)) return -1;
    }

    const std::size_t required = 8 * (count + 1);
    if (output == nullptr || capacity < required) return -2;

    std::uint8_t board[kSlots]{};
    std::uint64_t hash = 0;
    for (std::size_t slot = 0; slot < kSlots; ++slot) {
        const auto feature = static_cast<std::uint8_t>(input[state_start + slot]);
        board[slot] = feature;
        if (feature != 0)
            hash ^= static_cast<std::uint64_t>(input[1 + slot * kFeatures + feature - 1]);
    }
    store_hash(output, 0, hash);

    for (std::size_t edit = 0; edit < count; ++edit) {
        const auto slot = static_cast<std::size_t>(input[edits_start + 2 * edit]);
        const auto next = static_cast<std::uint8_t>(input[edits_start + 2 * edit + 1]);
        const auto previous = board[slot];
        if (previous != 0)
            hash ^= static_cast<std::uint64_t>(input[1 + slot * kFeatures + previous - 1]);
        if (next != 0)
            hash ^= static_cast<std::uint64_t>(input[1 + slot * kFeatures + next - 1]);
        board[slot] = next;
        store_hash(output, 8 * (edit + 1), hash);
    }
    return static_cast<std::int64_t>(required);
}
