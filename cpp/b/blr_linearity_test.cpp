#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxInput = 130;
constexpr std::size_t OutputBytes = 24;

void put_i64(std::array<std::uint8_t, OutputBytes>& out, std::size_t offset,
             std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i)
        out[offset + i] = static_cast<std::uint8_t>((bits >> (8 * i)) & 255);
}
}

extern "C" std::int64_t blr_linearity_test(const std::int64_t *values,
                                             std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t capacity) {
    if (values == nullptr || length < 2 || length > MaxInput) return -1;
    if (values[0] < 1 || values[0] > 6 || values[1] < 1 || values[1] > 32) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    const auto q = static_cast<std::size_t>(values[1]);
    const auto domain = std::size_t{1} << n;
    if (length != 2 + domain + 2 * q) return -1;
    const auto table = values + 2;
    const auto tape = table + domain;
    for (std::size_t i = 0; i < domain; ++i)
        if (table[i] != 0 && table[i] != 1) return -1;
    for (std::size_t i = 0; i < 2 * q; ++i)
        if (tape[i] < 0 || static_cast<std::uint64_t>(tape[i]) >= domain) return -1;

    std::size_t rounds = 0;
    bool accepted = true;
    for (std::size_t round = 0; round < q; ++round) {
        const auto x = static_cast<std::size_t>(tape[2 * round]);
        const auto y = static_cast<std::size_t>(tape[2 * round + 1]);
        ++rounds;
        if ((table[x] ^ table[y]) != table[x ^ y]) { accepted = false; break; }
    }
    if (output == nullptr || capacity < OutputBytes) return -2;
    std::array<std::uint8_t, OutputBytes> staged{};
    put_i64(staged, 0, accepted ? 1 : 0);
    put_i64(staged, 8, static_cast<std::int64_t>(rounds));
    put_i64(staged, 16, static_cast<std::int64_t>(3 * rounds));
    for (std::size_t i = 0; i < OutputBytes; ++i) output[i] = staged[i];
    return OutputBytes;
}
