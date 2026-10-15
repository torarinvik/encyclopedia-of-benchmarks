#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 256;
constexpr std::size_t HASH_CAPACITY = 512;

std::size_t hash_slot(std::int32_t value)
{
    const auto mixed = static_cast<std::uint64_t>(static_cast<std::uint32_t>(value)) * UINT64_C(2654435761);
    return static_cast<std::size_t>(static_cast<std::uint32_t>(mixed) >> 23);
}

std::size_t find_slot(const std::int32_t *keys, const bool *occupied, std::int32_t value)
{
    auto slot = hash_slot(value);
    for (std::size_t probes = 0; probes < HASH_CAPACITY; ++probes) {
        if (!occupied[slot] || keys[slot] == value) return slot;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return 0;
}

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t count_distinct_elements_in_window(const std::int64_t *input, std::size_t length,
                                                            std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (input[1] < 1 || input[1] > static_cast<std::int64_t>(n) || length != n + 2) return -1;
    const auto k = static_cast<std::size_t>(input[1]);
    const auto out_n = n - k + 1;
    for (std::size_t i = 0; i < n; ++i) if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
    if (output == nullptr || capacity < out_n * 8) return -2;

    std::int32_t keys[HASH_CAPACITY] = {}, counts[HASH_CAPACITY] = {};
    bool occupied[HASH_CAPACITY] = {};
    std::int64_t distinct = 0;
    for (std::size_t i = 0; i < k; ++i) {
        const auto value = static_cast<std::int32_t>(input[i + 2]);
        const auto slot = find_slot(keys, occupied, value);
        if (!occupied[slot]) { keys[slot] = value; occupied[slot] = true; counts[slot] = 0; }
        if (counts[slot]++ == 0) ++distinct;
    }
    put_i64_le(output, 0, distinct);
    for (std::size_t i = k; i < n; ++i) {
        const auto incoming = static_cast<std::int32_t>(input[i + 2]);
        auto slot = find_slot(keys, occupied, incoming);
        if (!occupied[slot]) { keys[slot] = incoming; occupied[slot] = true; counts[slot] = 0; }
        if (counts[slot]++ == 0) ++distinct;
        const auto outgoing = static_cast<std::int32_t>(input[i - k + 2]);
        slot = find_slot(keys, occupied, outgoing);
        if (--counts[slot] == 0) --distinct;
        put_i64_le(output, (i - k + 1) * 8, distinct);
    }
    return static_cast<std::int64_t>(out_n * 8);
}
