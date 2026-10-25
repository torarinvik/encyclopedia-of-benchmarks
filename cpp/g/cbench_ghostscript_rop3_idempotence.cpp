// Independent bounded profile; full Aladdin Free Public License v5 is bundled.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cbench_ghostscript_rop3_idempotence(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 2 || (length != 0 && values == nullptr) || length != 1) return -1;
    if (values[0] < 0 || values[0] > 255) return -1;
    const auto code = static_cast<std::uint64_t>(values[0]);
    for (unsigned bit = 1; bit < 8; bit += 2)
        if (((code >> bit) & 1) != 0 && ((code >> (bit - 1)) & 1) == 0) return 0;
    return 1;
}
