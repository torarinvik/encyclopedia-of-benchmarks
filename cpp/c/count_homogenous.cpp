/* Count contiguous runs of equal ASCII bytes. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t count_homogenous(const std::int64_t *input,
                                          std::size_t length) noexcept
{
    constexpr std::size_t max_text_bytes = 4096;
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_bytes)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != count + 1) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    }
    if (count == 0) return 0;
    std::size_t runs = 1;
    for (std::size_t i = 2; i <= count; ++i) {
        if (input[i] != input[i - 1]) ++runs;
    }
    return static_cast<std::int64_t>(runs);
}
