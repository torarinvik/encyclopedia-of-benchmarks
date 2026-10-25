// Independent ROP3 truth-table dependency profile; full AFPL v5 is bundled.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cbench_ghostscript_rop3_operand_usage(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 2 || (length != 0 && values == nullptr) || length != 1) return -1;
    if (values[0] < 0 || values[0] > 255) return -1;
    const auto code = static_cast<std::uint64_t>(values[0]);
    unsigned usage = 0;
    for (unsigned dimension = 0; dimension < 3; ++dimension) {
        const unsigned toggle = 1u << dimension;
        for (unsigned index = 0; index < 8; ++index) {
            if ((index & toggle) == 0 && ((code >> index) & 1) != ((code >> (index | toggle)) & 1)) {
                usage |= toggle;
                break;
            }
        }
    }
    return usage;
}
