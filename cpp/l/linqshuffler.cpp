/* Replay LINQ random-key sorting with the pinned .NET seeded Random sequence. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxParseableInputLength = 67;
constexpr std::size_t kMaxOutputBytes = 520;
constexpr std::int64_t kI32Min = -2'147'483'648LL;
constexpr std::int64_t kI32Max = 2'147'483'647LL;
constexpr std::int64_t kMbig = 2'147'483'647LL;

std::int64_t compat_next(std::array<std::int64_t, 56> &seed_array,
                         std::size_t &inext, std::size_t &inextp)
{
    if (++inext >= 56) inext = 1;
    if (++inextp >= 56) inextp = 1;

    std::int64_t sample = seed_array[inext] - seed_array[inextp];
    if (sample == kMbig) --sample;
    if (sample < 0) sample += kMbig;
    seed_array[inext] = sample;
    return sample;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t linqshuffler(const std::int64_t *input, std::size_t input_length,
                                      std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 2 || input_length > kMaxParseableInputLength) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t seed = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(kMaxN)
        || seed < kI32Min || seed > kI32Max) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (input_length != n + 2) return -1;

    std::array<std::int64_t, kMaxN> values{};
    std::array<std::int64_t, kMaxN> keys{};
    for (std::size_t index = 0; index < n; ++index) {
        const std::int64_t value = input[index + 2];
        if (value < kI32Min || value > kI32Max) return -1;
        values[index] = value;
    }

    const std::int64_t subtraction = seed == kI32Min ? kI32Max : (seed < 0 ? -seed : seed);
    std::array<std::int64_t, 56> seed_array{};
    std::int64_t mj = 161'803'398 - subtraction;
    seed_array[55] = mj;
    std::int64_t mk = 1;
    for (std::size_t i = 1; i < 55; ++i) {
        const std::size_t ii = (21 * i) % 55;
        seed_array[ii] = mk;
        mk = mj - mk;
        if (mk < 0) mk += kMbig;
        mj = seed_array[ii];
    }
    for (std::size_t pass = 0; pass < 4; ++pass) {
        for (std::size_t i = 1; i < 56; ++i) {
            const std::size_t offset_index = 1 + (i + 30) % 55;
            seed_array[i] -= seed_array[offset_index];
            if (seed_array[i] < 0) seed_array[i] += kMbig;
        }
    }

    std::size_t inext = 0;
    std::size_t inextp = 21;
    for (std::size_t index = 0; index < n; ++index)
        keys[index] = compat_next(seed_array, inext, inextp);

    // Strict comparison preserves original order for equal random keys.
    for (std::size_t index = 1; index < n; ++index) {
        const std::int64_t key = keys[index];
        const std::int64_t value = values[index];
        std::size_t cursor = index;
        while (cursor > 0 && keys[cursor - 1] > key) {
            keys[cursor] = keys[cursor - 1];
            values[cursor] = values[cursor - 1];
            --cursor;
        }
        keys[cursor] = key;
        values[cursor] = value;
    }

    const std::size_t output_bytes = 8 * (n + 1);
    if (output_bytes > kMaxOutputBytes || output == nullptr || output_capacity < output_bytes) return -2;
    store_i64_le(output, 0, n_value);
    for (std::size_t index = 0; index < n; ++index)
        store_i64_le(output, 8 * (index + 1), values[index]);
    return static_cast<std::int64_t>(output_bytes);
}
