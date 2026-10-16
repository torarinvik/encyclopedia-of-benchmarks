// Dispatch the seven pinned Python endianness helpers.
#include <cstddef>
#include <cstdint>

namespace {
std::int64_t signed_u64(std::uint64_t bits) noexcept {
    if (bits <= static_cast<std::uint64_t>(INT64_MAX)) return static_cast<std::int64_t>(bits);
    return -1 - static_cast<std::int64_t>(UINT64_MAX - bits);
}

std::uint64_t swap_bytes(std::uint64_t bits, std::size_t count) noexcept {
    std::uint64_t reversed = 0;
    for (std::size_t i = 0; i < count; ++i) {
        reversed = (reversed << 8) | (bits & 0xffU);
        bits >>= 8;
    }
    return reversed;
}
}

extern "C" std::int64_t endianness(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length == 0) return -1;
    const auto operation = input[0];
    if (operation >= 0 && operation <= 2) {
        if (length != 2) return -1;
        const auto value = input[1];
        if (operation == 0) {
            if (value < 0 || value > 65535) return -1;
            return static_cast<std::int64_t>(swap_bytes(static_cast<std::uint64_t>(value), 2));
        }
        if (operation == 1) {
            if (value < 0 || static_cast<std::uint64_t>(value) > 0xffffffffULL) return -1;
            return static_cast<std::int64_t>(swap_bytes(static_cast<std::uint64_t>(value), 4));
        }
        return signed_u64(swap_bytes(static_cast<std::uint64_t>(value), 8));
    }
    if (operation == 3 || operation == 4) {
        if (length < 3 || input[1] < 1 || input[1] > 8 || length != static_cast<std::size_t>(input[1]) + 2) return -1;
        const auto count = static_cast<std::size_t>(input[1]);
        std::uint64_t result = 0;
        for (std::size_t i = 0; i < count; ++i) {
            const auto byte = input[i + 2];
            if (byte < 0 || byte > 255) return -1;
            const auto shift = operation == 3 ? 8 * i : 8 * (count - 1 - i);
            result |= static_cast<std::uint64_t>(byte) << shift;
        }
        return signed_u64(result);
    }
    if (operation == 5 || operation == 6) {
        if (length != 3 || input[2] < 1 || input[2] > 8) return -1;
        const auto count = static_cast<std::size_t>(input[2]);
        const auto value = static_cast<std::uint64_t>(input[1]);
        if (count < 8 && (input[1] < 0 || (value >> (8 * count)) != 0)) return -1;
        return signed_u64(operation == 5 ? value : swap_bytes(value, count));
    }
    return -1;
}
