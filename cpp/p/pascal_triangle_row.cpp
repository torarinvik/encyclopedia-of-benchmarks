/* Compute one row of Pascal's triangle using in-place dynamic programming. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t pascal_triangle_row(std::int64_t row_index, std::uint8_t *output,
                                             std::size_t output_capacity) noexcept {
    if (row_index < 0 || row_index > 33) return -1;
    const std::size_t count = static_cast<std::size_t>(row_index) + 1;
    const std::size_t required = count * sizeof(std::uint32_t);
    if (output == nullptr || output_capacity < required) return -2;

    std::uint32_t coefficients[34];
    for (std::size_t column = 0; column < count; ++column) coefficients[column] = 1;
    for (std::size_t row = 2; row <= static_cast<std::size_t>(row_index); ++row)
        for (std::size_t column = row - 1; column > 0; --column)
            coefficients[column] += coefficients[column - 1];

    std::size_t position = 0;
    for (std::size_t column = 0; column < count; ++column)
        for (unsigned byte = 0; byte < 4; ++byte)
            output[position++] = static_cast<std::uint8_t>(coefficients[column] >> (byte * 8));
    return static_cast<std::int64_t>(position);
}
