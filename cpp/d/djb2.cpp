/* Port of TheAlgorithms/Python's 32-bit DJB2 hash on byte code points. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxBytes = 64;
constexpr std::size_t kMaxParsedBytes = 65;
}

extern "C" std::int64_t djb2(const std::int64_t *input, std::size_t length) noexcept
{
    if (length > kMaxParsedBytes || (length > 0 && input == nullptr)) return -1;
    if (length > kMaxBytes) return -1;
    std::uint32_t hash = UINT32_C(5381);
    for (std::size_t index = 0; index < length; ++index) {
        const auto code_point = input[index];
        if (code_point < 0 || code_point > 255) return -1;
        hash = hash * UINT32_C(33) + static_cast<std::uint32_t>(code_point);
    }
    return static_cast<std::int64_t>(hash);
}
