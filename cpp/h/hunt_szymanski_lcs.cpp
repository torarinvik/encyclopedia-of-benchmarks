// Return the LCS length through Hunt-Szymanski matching positions and LIS tails.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t hunt_szymanski_lcs(const std::int64_t *input,
                                            std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > 131) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t m_value = input[1];
    if (n_value < 0 || n_value > 64 || m_value < 0 || m_value > 64 ||
        length != static_cast<std::size_t>(2 + n_value + m_value)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::size_t m = static_cast<std::size_t>(m_value);
    for (std::size_t i = 0; i < n + m; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;
    }

    std::int32_t right_positions[128 * 64];
    std::int32_t position_count[128]{};
    std::int32_t tails[64];
    for (std::size_t j = 0; j < m; ++j) {
        const std::size_t symbol = static_cast<std::size_t>(input[2 + n + j]);
        const std::int32_t count = position_count[symbol];
        right_positions[symbol * 64 + static_cast<std::size_t>(count)] =
            static_cast<std::int32_t>(j);
        position_count[symbol] = count + 1;
    }

    std::int32_t tail_count = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::size_t symbol = static_cast<std::size_t>(input[2 + i]);
        for (std::int32_t count = position_count[symbol]; count > 0; --count) {
            const std::int32_t position = right_positions[
                symbol * 64 + static_cast<std::size_t>(count - 1)];
            std::int32_t low = 0;
            std::int32_t high = tail_count;
            while (low < high) {
                const std::int32_t middle = low + (high - low) / 2;
                if (tails[middle] >= position) high = middle;
                else low = middle + 1;
            }
            if (low == tail_count) tails[tail_count++] = position;
            else tails[low] = position;
        }
    }
    return tail_count;
}
