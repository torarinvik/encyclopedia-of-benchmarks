/* One majority-clock step for the three source-configured A5 LFSRs. */
#include <cstddef>
#include <cstdint>

namespace {
void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>((bits >> (8 * byte)) & 0xffu);
}
}

extern "C" std::int64_t composite_lfsr_majority_clock(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 3) return -1;
    if (input[0] < 0 || input[0] > 524287 || input[1] < 0 || input[1] > 4194303
        || input[2] < 0 || input[2] > 8388607) return -1;
    if (output == nullptr || output_capacity < 32) return -2;
    std::uint64_t s1 = static_cast<std::uint64_t>(input[0]);
    std::uint64_t s2 = static_cast<std::uint64_t>(input[1]);
    std::uint64_t s3 = static_cast<std::uint64_t>(input[2]);
    const auto c1 = (s1 >> 8) & 1u, c2 = (s2 >> 10) & 1u, c3 = (s3 >> 10) & 1u;
    const std::uint64_t majority = c1 + c2 + c3 >= 2 ? 1u : 0u;
    const std::uint64_t emitted = ((s1 >> 18) ^ (s2 >> 21) ^ (s3 >> 22)) & 1u;
    if (c1 == majority) s1 = ((s1 << 1) & 524287u) | (((s1 >> 13) ^ (s1 >> 16) ^ (s1 >> 17) ^ (s1 >> 18)) & 1u);
    if (c2 == majority) s2 = ((s2 << 1) & 4194303u) | (((s2 >> 20) ^ (s2 >> 21)) & 1u);
    if (c3 == majority) s3 = ((s3 << 1) & 8388607u) | (((s3 >> 7) ^ (s3 >> 20) ^ (s3 >> 21) ^ (s3 >> 22)) & 1u);
    write_i64_le(output, 0, static_cast<std::int64_t>(emitted));
    write_i64_le(output, 8, static_cast<std::int64_t>(s1));
    write_i64_le(output, 16, static_cast<std::int64_t>(s2));
    write_i64_le(output, 24, static_cast<std::int64_t>(s3));
    return 32;
}
