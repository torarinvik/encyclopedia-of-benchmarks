#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 64;
constexpr std::size_t MAX_TRIPLETS = 2048;
constexpr std::size_t HASH_CAPACITY = 128;
constexpr std::size_t BYTES_PER_TRIPLET = 12;

std::size_t hash_slot(std::int64_t value) { return static_cast<std::size_t>(((value + 100000) * 37) % HASH_CAPACITY); }

bool seen_contains(const std::int64_t *keys, const bool *occupied, std::int64_t value)
{
    auto slot = hash_slot(value);
    for (std::size_t probes = 0; probes < HASH_CAPACITY; ++probes) {
        if (!occupied[slot]) return false;
        if (keys[slot] == value) return true;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return false;
}

void seen_add(std::int64_t *keys, bool *occupied, std::int64_t value)
{
    auto slot = hash_slot(value);
    for (std::size_t probes = 0; probes < HASH_CAPACITY; ++probes) {
        if (!occupied[slot]) { keys[slot] = value; occupied[slot] = true; return; }
        if (keys[slot] == value) return;
        slot = (slot + 1) % HASH_CAPACITY;
    }
}

void sort3(std::int64_t &a, std::int64_t &b, std::int64_t &c)
{
    std::int64_t t;
    if (a > b) { t = a; a = b; b = t; }
    if (b > c) { t = b; b = c; c = t; }
    if (a > b) { t = a; a = b; b = t; }
}

bool already_output(const std::int64_t *triples, std::size_t count, std::int64_t a, std::int64_t b, std::int64_t c)
{
    for (std::size_t i = 0; i < count; ++i)
        if (triples[i * 3] == a && triples[i * 3 + 1] == b && triples[i * 3 + 2] == c) return true;
    return false;
}

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < 4; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t find_triplets_with_0_sum_hashing(const std::int64_t *input, std::size_t length,
                                                           std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length > MAX_ITEMS || (length > 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < -100000 || input[i] > 100000) return -1;
    std::int64_t triples[MAX_TRIPLETS * 3] = {};
    std::size_t count = 0;
    for (std::size_t i = 0; i + 2 < length; ++i) {
        std::int64_t keys[HASH_CAPACITY] = {};
        bool occupied[HASH_CAPACITY] = {};
        for (std::size_t j = i + 1; j < length; ++j) {
            const auto other = input[j];
            const auto required = -input[i] - other;
            if (required >= -100000 && required <= 100000 && seen_contains(keys, occupied, required)) {
                auto a = input[i], b = other, c = required;
                sort3(a, b, c);
                if (!already_output(triples, count, a, b, c) && count < MAX_TRIPLETS) {
                    triples[count * 3] = a; triples[count * 3 + 1] = b; triples[count * 3 + 2] = c;
                    ++count;
                }
            }
            seen_add(keys, occupied, other);
        }
    }
    if (count == 0) return 0;
    const auto needed = count * BYTES_PER_TRIPLET;
    if (output == nullptr || output_capacity < needed) return -2;
    for (std::size_t i = 0; i < count * 3; ++i) write_i32_le(output, i * 4, triples[i]);
    return static_cast<std::int64_t>(count);
}
