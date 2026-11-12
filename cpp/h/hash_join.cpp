#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxRows = 8;
constexpr std::size_t kHashCapacity = 17;
constexpr std::size_t kMaxInput = 19;
constexpr std::size_t kMaxOutput = 64;

std::size_t bucket_for(std::int64_t key) noexcept
{
    auto remainder = key % static_cast<std::int64_t>(kHashCapacity);
    if (remainder < 0) remainder += static_cast<std::int64_t>(kHashCapacity);
    return static_cast<std::size_t>(remainder);
}
}

extern "C" std::int64_t hash_join(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxRows)
        || input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxRows)) return -1;
    const auto left_count = static_cast<std::size_t>(input[0]);
    const auto right_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + left_count + right_count) return -1;

    const bool build_left = left_count < right_count;
    const auto build_count = build_left ? left_count : right_count;
    const auto probe_count = build_left ? right_count : left_count;
    const auto build_offset = build_left ? std::size_t{2} : 2 + left_count;
    const auto probe_offset = build_left ? 2 + left_count : std::size_t{2};
    std::array<std::int64_t, kHashCapacity> keys{};
    std::array<int, kHashCapacity> heads;
    std::array<int, kHashCapacity> tails;
    std::array<int, kMaxRows> next_row;
    std::array<bool, kHashCapacity> occupied{};
    std::array<std::uint8_t, kMaxOutput> staged{};
    heads.fill(-1);
    tails.fill(-1);
    next_row.fill(-1);

    for (std::size_t row = 0; row < build_count; ++row) {
        const auto key = input[build_offset + row];
        auto slot = bucket_for(key);
        while (occupied[slot] && keys[slot] != key) slot = (slot + 1) % kHashCapacity;
        if (!occupied[slot]) { occupied[slot] = true; keys[slot] = key; }
        if (tails[slot] < 0) heads[slot] = static_cast<int>(row);
        else next_row[static_cast<std::size_t>(tails[slot])] = static_cast<int>(row);
        tails[slot] = static_cast<int>(row);
    }

    std::size_t match_count = 0;
    for (std::size_t probe_row = 0; probe_row < probe_count; ++probe_row) {
        const auto key = input[probe_offset + probe_row];
        auto slot = bucket_for(key);
        while (occupied[slot] && keys[slot] != key) slot = (slot + 1) % kHashCapacity;
        if (!occupied[slot]) continue;
        for (int build_row = heads[slot]; build_row >= 0; build_row = next_row[static_cast<std::size_t>(build_row)]) {
            const auto left_id = build_left ? static_cast<std::size_t>(build_row) : probe_row;
            const auto right_id = build_left ? probe_row : static_cast<std::size_t>(build_row);
            staged[match_count++] = static_cast<std::uint8_t>((left_id << 4) | right_id);
        }
    }
    if (output == nullptr || capacity < match_count) return -2;
    for (std::size_t i = 0; i < match_count; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(match_count);
}
