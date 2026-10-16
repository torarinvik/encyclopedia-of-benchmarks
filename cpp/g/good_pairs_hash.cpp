// Count equal-value index pairs with a bounded open-addressed frequency table.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ARRAY_LENGTH = 256;
constexpr std::size_t MAX_INPUT_LENGTH = 258;
constexpr std::size_t TABLE_SIZE = 512;
}

extern "C" std::int64_t good_pairs_hash(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t declared = input[0];
    if (declared < 0 || declared > static_cast<std::int64_t>(MAX_ARRAY_LENGTH) || length != static_cast<std::size_t>(declared) + 1) return -1;
    const std::size_t count = static_cast<std::size_t>(declared);
    std::int64_t keys[TABLE_SIZE] = {};
    std::uint64_t frequencies[TABLE_SIZE] = {};
    bool occupied[TABLE_SIZE] = {};
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < -1000000 || value > 1000000) return -1;
        std::size_t slot = static_cast<std::size_t>((static_cast<std::uint64_t>(value + 1000000) * UINT64_C(2654435761)) & (TABLE_SIZE - 1));
        while (occupied[slot] && keys[slot] != value) slot = (slot + 1) & (TABLE_SIZE - 1);
        if (!occupied[slot]) { occupied[slot] = true; keys[slot] = value; }
        ++frequencies[slot];
    }
    std::uint64_t pairs = 0;
    for (std::size_t slot = 0; slot < TABLE_SIZE; ++slot) {
        const std::uint64_t frequency = frequencies[slot];
        if (frequency > 1) pairs += frequency * (frequency - 1) / 2;
    }
    return static_cast<std::int64_t>(pairs);
}
