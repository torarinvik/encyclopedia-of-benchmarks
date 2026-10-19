#include <cstddef>
#include <cstdint>

namespace {
constexpr int MATRIX_SIZE = 10;
constexpr int CELL_COUNT = MATRIX_SIZE * MATRIX_SIZE;
constexpr std::int64_t MAX_ITERATIONS = 4096;
constexpr std::size_t MAX_OUTPUT_BYTES = 23;

void append_integer(int value, std::uint8_t *buffer, std::size_t &used)
{
    std::uint8_t reversed[10];
    std::size_t count = 0;
    do {
        reversed[count++] = static_cast<std::uint8_t>('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[used++] = reversed[--count];
}
}

extern "C" std::int64_t shootout_matrix(std::int64_t iteration_count,
                                           std::uint8_t *output,
                                           std::size_t output_capacity) noexcept
{
    if (iteration_count < 0 || iteration_count > MAX_ITERATIONS) return -1;

    int left[CELL_COUNT], right[CELL_COUNT], product[CELL_COUNT];
    for (int index = 0; index < CELL_COUNT; ++index) {
        left[index] = index + 1;
        right[index] = index + 1;
        product[index] = index + 1;
    }

    for (std::int64_t iteration = 0; iteration < iteration_count; ++iteration) {
        for (int row = 0; row < MATRIX_SIZE; ++row) {
            for (int column = 0; column < MATRIX_SIZE; ++column) {
                int value = 0;
                for (int inner = 0; inner < MATRIX_SIZE; ++inner)
                    value += left[row * MATRIX_SIZE + inner] * right[inner * MATRIX_SIZE + column];
                product[row * MATRIX_SIZE + column] = value;
            }
        }
    }

    const int selected[4] = {product[0], product[23], product[32], product[44]};
    std::uint8_t staged[MAX_OUTPUT_BYTES];
    std::size_t used = 0;
    for (std::size_t index = 0; index < 4; ++index) {
        if (index != 0) staged[used++] = static_cast<std::uint8_t>(' ');
        append_integer(selected[index], staged, used);
    }
    staged[used++] = static_cast<std::uint8_t>('\n');

    if (output == nullptr || output_capacity < used) return -2;
    for (std::size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(used);
}
