#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_STRINGS = 256;
constexpr std::size_t MAX_LENGTH = 32;
constexpr std::size_t MAX_INPUT = 1 + MAX_STRINGS * (1 + MAX_LENGTH) + 1;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);

struct EncodedString { std::uint8_t bytes[MAX_LENGTH]{}; std::size_t length = 0; };

std::size_t bucket(const EncodedString& value, std::size_t digit) {
    return digit >= value.length ? 0 : std::size_t(value.bytes[digit]) + 1;
}

void msd_sort(EncodedString* values, EncodedString* auxiliary,
              std::size_t low, std::size_t high, std::size_t digit) {
    if (high - low < 2 || digit >= MAX_LENGTH) return;
    std::size_t counts[257]{};
    for (std::size_t i = low; i < high; ++i) ++counts[bucket(values[i], digit)];
    std::size_t starts[257], next[257], position = low;
    for (std::size_t b = 0; b < 257; ++b) {
        starts[b] = next[b] = position;
        position += counts[b];
    }
    for (std::size_t i = low; i < high; ++i) {
        const std::size_t b = bucket(values[i], digit);
        auxiliary[next[b]++] = values[i];
    }
    for (std::size_t i = low; i < high; ++i) values[i] = auxiliary[i];
    for (std::size_t b = 1; b < 257; ++b) {
        const std::size_t first = starts[b], last = first + counts[b];
        if (last - first > 1) msd_sort(values, auxiliary, first, last, digit + 1);
    }
}
}

extern "C" std::int64_t msd_radix_string_sorter(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length == 0 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > std::int64_t(MAX_STRINGS)) return -1;
    const std::size_t count = std::size_t(input[0]);
    EncodedString values[MAX_STRINGS]{}, auxiliary[MAX_STRINGS]{};
    std::size_t position = 1;
    for (std::size_t i = 0; i < count; ++i) {
        if (position >= length || input[position] < 0 || input[position] > std::int64_t(MAX_LENGTH)) return -1;
        const std::size_t n = std::size_t(input[position++]);
        if (n > length - position) return -1;
        values[i].length = n;
        for (std::size_t d = 0; d < n; ++d) {
            if (input[position] < 0 || input[position] > 255) return -1;
            values[i].bytes[d] = std::uint8_t(input[position++]);
        }
    }
    if (position != length) return -1;
    if (count > 1) msd_sort(values, auxiliary, 0, count, 0);
    std::uint64_t hash = FNV_OFFSET;
    hash = (hash ^ std::uint8_t(count & 255)) * FNV_PRIME;
    hash = (hash ^ std::uint8_t((count >> 8) & 255)) * FNV_PRIME;
    for (std::size_t i = 0; i < count; ++i) {
        hash = (hash ^ std::uint8_t(values[i].length)) * FNV_PRIME;
        for (std::size_t d = 0; d < values[i].length; ++d)
            hash = (hash ^ values[i].bytes[d]) * FNV_PRIME;
    }
    return std::int64_t(hash & UINT64_C(0x7fffffffffffffff));
}
