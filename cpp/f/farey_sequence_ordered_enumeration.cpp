#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxOrder = 32;

std::int64_t farey_count(std::int64_t order) {
    std::int64_t a = 0, b = 1, c = 1, d = order;
    std::int64_t count = 1;
    for (;;) {
        ++count;
        if (c == d) break;
        const std::int64_t k = (order + b) / d;
        const std::int64_t next_c = k * c - a;
        const std::int64_t next_d = k * d - b;
        a = c;
        b = d;
        c = next_c;
        d = next_d;
    }
    return count;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>((bits >> (8 * byte)) & 0xffu);
    }
}
}

extern "C" std::int64_t farey_sequence_ordered_enumeration(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length != 1) return -1;
    const std::int64_t order = input[0];
    if (order < 1 || order > kMaxOrder) return -1;
    const std::int64_t count = farey_count(order);
    const std::size_t required = static_cast<std::size_t>(1 + 2 * count) * 8;
    if (output == nullptr || capacity < required) return -2;

    store_i64_le(output, 0, count);
    store_i64_le(output, 8, 0);
    store_i64_le(output, 16, 1);
    std::int64_t a = 0, b = 1, c = 1, d = order;
    std::size_t position = 24;
    for (;;) {
        store_i64_le(output, position, c);
        store_i64_le(output, position + 8, d);
        position += 16;
        if (c == d) break;
        const std::int64_t k = (order + b) / d;
        const std::int64_t next_c = k * c - a;
        const std::int64_t next_d = k * d - b;
        a = c;
        b = d;
        c = next_c;
        d = next_d;
    }
    return static_cast<std::int64_t>(required);
}
