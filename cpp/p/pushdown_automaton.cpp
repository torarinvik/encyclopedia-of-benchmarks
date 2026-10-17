/* Recognize the bounded language (1|2)^n 0^n with a pushdown-style counter. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t pushdown_automaton(const std::int64_t *values,
                                            std::size_t length) noexcept
{
    constexpr std::int64_t max_byte_length = 256;
    constexpr std::size_t max_input_length = 257;
    if (values == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t byte_length = values[0];
    if (byte_length < 0 || byte_length > max_byte_length) return -1;
    const auto count = static_cast<std::size_t>(byte_length);
    if (length != count + 1) return -1;

    for (std::size_t index = 0; index < count; ++index) {
        const auto byte = values[index + 1];
        if (byte < 48 || byte > 50) return -1;
    }
    if (count == 0 || count % 2 != 0) return 0;

    const std::size_t half = count / 2;
    for (std::size_t index = 0; index < half; ++index)
        if (values[index + 1] != 49 && values[index + 1] != 50) return 0;
    for (std::size_t index = half; index < count; ++index)
        if (values[index + 1] != 48) return 0;
    return 1;
}
