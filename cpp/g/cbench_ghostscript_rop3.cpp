// Independent bounded ROP3 profile; upstream copyright and full AFPL v5
// terms are recorded in benchmarks/g/cbench_ghostscript_rop3/LICENSE.txt.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cbench_ghostscript_rop3(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 5 || (length != 0 && values == nullptr) || length != 4) return -1;
    for (std::size_t i = 0; i < 3; ++i)
        if (values[i] < 0 || values[i] > INT64_C(4294967295)) return -1;
    if (values[3] < 0 || values[3] > 255) return -1;
    const auto d = static_cast<std::uint64_t>(values[0]);
    const auto s = static_cast<std::uint64_t>(values[1]);
    const auto t = static_cast<std::uint64_t>(values[2]);
    const auto code = static_cast<std::uint64_t>(values[3]);
    std::uint64_t result = 0;
    for (unsigned bit = 0; bit < 32; ++bit) {
        const unsigned index = static_cast<unsigned>(((t >> bit) & 1) << 2) |
            static_cast<unsigned>(((s >> bit) & 1) << 1) | static_cast<unsigned>((d >> bit) & 1);
        if ((code >> index) & 1) result |= UINT64_C(1) << bit;
    }
    return static_cast<std::int64_t>(result);
}
