/* Hash a bounded ASCII codepoint array with the Python ELF recurrence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t elf_hash(const std::int64_t *input,
                                  std::size_t length) noexcept {
    constexpr std::size_t kMaxCodepoints = 8;
    if (length > kMaxCodepoints || (input == nullptr && length != 0)) return -1;

    std::uint64_t hash = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto codepoint = input[index];
        if (codepoint < 0 || codepoint > 127) return -1;

        hash = (hash << 4) + static_cast<std::uint64_t>(codepoint);
        const auto high = hash & UINT64_C(0xF0000000);
        if (high != 0) hash ^= high >> 24;
        hash ^= high;
    }
    return static_cast<std::int64_t>(hash);
}
