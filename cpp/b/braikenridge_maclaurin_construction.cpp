/* Compute the six exact 5x5 determinant coefficients of a conic. */
#include <cstddef>
#include <cstdint>

static std::int64_t determinant(const std::int64_t features[5][6], const std::uint8_t columns[5])
{
    std::int64_t paths[32]{};
    paths[0] = 1;
    for (std::size_t row = 0; row < 5; ++row) {
        std::int64_t next[32]{};
        for (std::size_t mask = 0; mask < 32; ++mask) {
            std::size_t selected = 0;
            for (std::size_t bit = 0; bit < 5; ++bit) selected += (mask >> bit) & 1U;
            if (selected != row || paths[mask] == 0) continue;
            for (std::size_t column = 0; column < 5; ++column) {
                const auto bit = std::size_t{1} << column;
                if ((mask & bit) != 0) continue;
                std::size_t inversions = 0;
                for (std::size_t previous = column + 1; previous < 5; ++previous)
                    inversions += (mask >> previous) & 1U;
                const auto term = paths[mask] * features[row][columns[column]];
                next[mask | bit] += (inversions & 1U) ? -term : term;
            }
        }
        for (std::size_t mask = 0; mask < 32; ++mask) paths[mask] = next[mask];
    }
    return paths[31];
}

extern "C" std::int64_t braikenridge_maclaurin_construction(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length != 10) return -2;
    std::int64_t features[5][6]{};
    for (std::size_t point = 0; point < 5; ++point) {
        const auto x = values[2 * point];
        const auto y = values[2 * point + 1];
        if (x < -10 || x > 10 || y < -10 || y > 10) return -2;
        features[point][0] = x * x;
        features[point][1] = x * y;
        features[point][2] = y * y;
        features[point][3] = x;
        features[point][4] = y;
        features[point][5] = 1;
    }
    static constexpr std::uint8_t columns[6][5] = {
        {1, 2, 3, 4, 5}, {0, 2, 3, 4, 5}, {0, 1, 3, 4, 5},
        {0, 1, 2, 4, 5}, {0, 1, 2, 3, 5}, {0, 1, 2, 3, 4}
    };
    static constexpr std::int8_t signs[6] = {1, -1, 1, -1, 1, -1};
    std::int64_t coefficients[6];
    for (std::size_t index = 0; index < 6; ++index)
        coefficients[index] = signs[index] * determinant(features, columns[index]);
    if (output_capacity < 48 || output == nullptr) return -2;
    for (std::size_t index = 0; index < 6; ++index) {
        const auto bits = static_cast<std::uint64_t>(coefficients[index]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[8 * index + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return 6;
}
