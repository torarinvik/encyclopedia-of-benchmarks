#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 32;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr std::size_t max_words = 96;
constexpr std::size_t max_word_length = 32;
constexpr std::size_t max_input_values = 4096;
constexpr std::uint64_t rng_modulus = 2147483647;

std::uint64_t next_random(std::uint64_t& state) noexcept {
    state = state * UINT64_C(48271) % rng_modulus;
    return state;
}

void shuffle(std::size_t* items, std::size_t count, std::uint64_t& state) noexcept {
    for (std::size_t remaining = count; remaining > 1; --remaining) {
        const auto other = static_cast<std::size_t>(next_random(state) % remaining);
        const auto temporary = items[remaining - 1];
        items[remaining - 1] = items[other];
        items[other] = temporary;
    }
}

bool is_ascii_letter(std::int64_t value) noexcept {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}
}  // namespace

extern "C" std::int64_t word_search_generator(const std::int64_t* values,
    std::size_t length, std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 4 || length > max_input_values) return -1;
    const auto width_value = values[0];
    const auto height_value = values[1];
    const auto seed_value = values[2];
    const auto word_count_value = values[3];
    if (width_value < 1 || width_value > static_cast<std::int64_t>(max_dimension) ||
        height_value < 1 || height_value > static_cast<std::int64_t>(max_dimension) ||
        seed_value < 1 || seed_value >= static_cast<std::int64_t>(rng_modulus) ||
        word_count_value < 0 || word_count_value > static_cast<std::int64_t>(max_words)) return -1;

    const auto width = static_cast<std::size_t>(width_value);
    const auto height = static_cast<std::size_t>(height_value);
    const auto word_count = static_cast<std::size_t>(word_count_value);
    std::size_t position = 4;
    for (std::size_t word = 0; word < word_count; ++word) {
        if (position >= length) return -1;
        const auto word_length_value = values[position++];
        if (word_length_value < 1 || word_length_value > static_cast<std::int64_t>(max_word_length) ||
            static_cast<std::uint64_t>(word_length_value) > length - position) return -1;
        const auto word_length = static_cast<std::size_t>(word_length_value);
        for (std::size_t offset = 0; offset < word_length; ++offset)
            if (!is_ascii_letter(values[position + offset])) return -1;
        position += word_length;
    }
    if (position != length) return -1;

    const auto cells = width * height;
    if (output == nullptr || output_capacity < cells) return -2;
    std::array<std::uint8_t, max_cells> board{};
    constexpr int row_delta[8] = {-1, -1, 0, 1, 1, 1, 0, -1};
    constexpr int column_delta[8] = {0, 1, 1, 1, 0, -1, -1, -1};
    std::uint64_t state = static_cast<std::uint64_t>(seed_value);
    position = 4;

    for (std::size_t word = 0; word < word_count; ++word) {
        const auto word_length = static_cast<std::size_t>(values[position++]);
        const auto word_start = position;
        position += word_length;
        std::array<std::size_t, max_dimension> rows{};
        std::array<std::size_t, max_dimension> columns{};
        for (std::size_t row = 0; row < height; ++row) rows[row] = row;
        for (std::size_t column = 0; column < width; ++column) columns[column] = column;
        shuffle(rows.data(), height, state);
        shuffle(columns.data(), width, state);
        const auto direction = static_cast<std::size_t>(next_random(state) % 8);
        bool placed = false;

        for (std::size_t row_index = 0; row_index < height && !placed; ++row_index) {
            for (std::size_t column_index = 0; column_index < width && !placed; ++column_index) {
                const int row = static_cast<int>(rows[row_index]);
                const int column = static_cast<int>(columns[column_index]);
                const int last_row = row + (static_cast<int>(word_length) - 1) * row_delta[direction];
                const int last_column = column + (static_cast<int>(word_length) - 1) * column_delta[direction];
                if (last_row < 0 || last_row >= static_cast<int>(height) ||
                    last_column < 0 || last_column >= static_cast<int>(width)) continue;
                bool available = true;
                for (std::size_t offset = 0; offset < word_length; ++offset) {
                    const int current_row = row + static_cast<int>(offset) * row_delta[direction];
                    const int current_column = column + static_cast<int>(offset) * column_delta[direction];
                    if (board[static_cast<std::size_t>(current_row) * width +
                              static_cast<std::size_t>(current_column)] != 0) {
                        available = false;
                        break;
                    }
                }
                if (!available) continue;
                for (std::size_t offset = 0; offset < word_length; ++offset) {
                    const int current_row = row + static_cast<int>(offset) * row_delta[direction];
                    const int current_column = column + static_cast<int>(offset) * column_delta[direction];
                    board[static_cast<std::size_t>(current_row) * width +
                          static_cast<std::size_t>(current_column)] =
                        static_cast<std::uint8_t>(values[word_start + offset]);
                }
                placed = true;
            }
        }
    }
    for (std::size_t index = 0; index < cells; ++index) output[index] = board[index];
    return static_cast<std::int64_t>(cells);
}
