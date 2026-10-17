/* Construct the source-compatible shortest common supersequence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t shortest_common_supersequence(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > 130) return -1;
    const std::int64_t m_value = input[0], n_value = input[1];
    if (m_value < 0 || m_value > 64 || n_value < 0 || n_value > 64) return -1;
    const std::size_t m = static_cast<std::size_t>(m_value);
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (length != 2 + m + n) return -1;
    for (std::size_t index = 0; index < m + n; ++index)
        if (input[2 + index] < 32 || input[2 + index] > 126) return -1;

    std::int64_t lcs[65][65]{};
    for (std::size_t i = 1; i <= m; ++i) {
        for (std::size_t j = 1; j <= n; ++j) {
            if (input[1 + i] == input[1 + m + j])
                lcs[i][j] = lcs[i - 1][j - 1] + 1;
            else
                lcs[i][j] = lcs[i - 1][j] > lcs[i][j - 1]
                    ? lcs[i - 1][j] : lcs[i][j - 1];
        }
    }

    std::uint8_t reversed[128];
    std::size_t used = 0, i = m, j = n;
    while (i > 0 && j > 0) {
        if (input[1 + i] == input[1 + m + j]) {
            reversed[used++] = static_cast<std::uint8_t>(input[1 + i]);
            --i;
            --j;
        } else if (lcs[i - 1][j] > lcs[i][j - 1]) {
            reversed[used++] = static_cast<std::uint8_t>(input[1 + i]);
            --i;
        } else {
            /* The pinned implementations choose Y when the LCS values tie. */
            reversed[used++] = static_cast<std::uint8_t>(input[1 + m + j]);
            --j;
        }
    }
    while (i > 0) reversed[used++] = static_cast<std::uint8_t>(input[1 + i--]);
    while (j > 0) reversed[used++] = static_cast<std::uint8_t>(input[1 + m + j--]);

    if (output == nullptr || capacity < used) return -2;
    for (std::size_t index = 0; index < used; ++index)
        output[index] = reversed[used - 1 - index];
    return static_cast<std::int64_t>(used);
}
