// Compare three source-provided methods for counting 32-bit set bits.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t count_number_of_one_bits(std::int64_t number,
                                                   std::int64_t method) noexcept {
    if (number < 0 || static_cast<std::uint64_t>(number) > UINT64_C(4294967295) ||
        method < 0 || method > 2) return -1;
    auto remaining = static_cast<std::uint32_t>(number);
    std::int64_t count = 0;
    if (method == 0) {
        while (remaining != 0) { remaining &= remaining - 1U; ++count; }
        return count;
    }
    if (method == 1) {
        while (remaining != 0) {
            if ((remaining % 2U) == 1U) ++count;
            remaining >>= 1;
        }
        return count;
    }
    std::int64_t lookup[256];
    lookup[0] = 0;
    for (std::size_t index = 1; index < 256; ++index)
        lookup[index] = lookup[index >> 1] + static_cast<std::int64_t>(index & 1U);
    return lookup[remaining & 0xffU] + lookup[(remaining >> 8) & 0xffU]
         + lookup[(remaining >> 16) & 0xffU] + lookup[(remaining >> 24) & 0xffU];
}
