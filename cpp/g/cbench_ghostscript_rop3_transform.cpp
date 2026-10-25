// Independent ROP3 truth-table transforms; full AFPL v5 is bundled.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cbench_ghostscript_rop3_transform(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 3 || (length != 0 && values == nullptr) || length != 2) return -1;
    if (values[0] < 0 || values[0] > 14 || values[1] < 0 || values[1] > 255) return -1;
    const unsigned mode = static_cast<unsigned>(values[0]);
    const auto code = static_cast<std::uint64_t>(values[1]);
    std::uint64_t result = 0;
    for (unsigned index = 0; index < 8; ++index) {
        const unsigned d = index & 1u, s = (index >> 1) & 1u, t = (index >> 2) & 1u;
        unsigned source_index = index;
        int forced = -1;
        if (mode <= 2) source_index ^= 1u << mode;
        else if (mode <= 8) {
            const unsigned dimension = (mode - 3) / 2, pinned = (mode - 3) & 1u;
            source_index = (index & ~(1u << dimension)) | (pinned << dimension);
        } else if (mode == 9) source_index = (index & ~6u) | (s << 2) | (t << 1);
        else if (mode <= 13) {
            const unsigned operand = mode < 12 ? s : t, required = (mode - 10) & 1u;
            if (operand == required) forced = static_cast<int>(d);
        } else forced = 1 - static_cast<int>((code >> index) & 1u);
        const unsigned bit = forced < 0 ? static_cast<unsigned>((code >> source_index) & 1u) : static_cast<unsigned>(forced);
        result |= static_cast<std::uint64_t>(bit) << index;
    }
    return static_cast<std::int64_t>(result);
}
