#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8;
constexpr std::size_t max_input_words = 1 + max_n * max_n;
constexpr std::size_t max_output_words = 1 + max_n * max_n;
constexpr std::size_t max_output_bytes = 4 * max_output_words;

bool search_path(const std::int32_t* maze, std::int32_t* path, int n, int row, int col) {
    const int index = row * n + col;
    path[index] = 1;
    if (row == n - 1 && col == n - 1) return true;
    if (col + 1 < n && maze[index + 1] == 1 && search_path(maze, path, n, row, col + 1)) return true;
    if (row + 1 < n && maze[index + n] == 1 && search_path(maze, path, n, row + 1, col)) return true;
    path[index] = 0;
    return false;
}
void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t rat_maze(const std::int32_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_words) return -1;
    const auto n = input[0];
    if (n < 1 || n > max_n || length != 1 + static_cast<std::size_t>(n) * static_cast<std::size_t>(n) || input[1] != 1) return -1;
    const auto cells = static_cast<std::size_t>(n) * static_cast<std::size_t>(n);
    for (std::size_t i = 0; i < cells; ++i) if (input[1 + i] < 0 || input[1 + i] > 1) return -1;
    std::int32_t path[max_n * max_n]{};
    const bool found = search_path(input + 1, path, n, 0, 0);
    const auto word_count = found ? 1 + cells : 1;
    const auto bytes = word_count * 4;
    if (output == nullptr || capacity < bytes) return -2;
    std::uint8_t buffer[max_output_bytes];
    put_i32_le(buffer, 0, found ? 1 : 0);
    if (found) for (std::size_t i = 0; i < cells; ++i) put_i32_le(buffer, (i + 1) * 4, path[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}
