#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_key_length = 25;
constexpr std::size_t max_text_length = 128;
constexpr std::size_t max_parseable_input_values = 3 + max_key_length + max_text_length + 1;
constexpr std::uint64_t fnv_offset_basis = 14695981039346656037ull;
constexpr std::uint64_t fnv_prime = 1099511628211ull;
constexpr std::uint64_t low_63_mask = 0x7fffffffffffffffULL;
constexpr char alphabet[] = "ABCDEFGHIKLMNOPQRSTUVWXYZ";

bool is_letter(std::int64_t value) noexcept
{
    return value >= 'A' && value <= 'Z' && value != 'J';
}

void add_square_letter(std::uint8_t square[25], bool seen[128], std::size_t& count,
                       std::uint8_t letter) noexcept
{
    if (seen[letter]) return;
    seen[letter] = true;
    square[count++] = letter;
}

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) noexcept
{
    return (hash ^ static_cast<std::uint64_t>(byte)) * fnv_prime;
}
} // namespace

extern "C" std::int64_t playfair_cipher(const std::int64_t* values,
                                         std::size_t length) noexcept
{
    if (values == nullptr || length < 3 || length > max_parseable_input_values) return -1;
    const std::int64_t operation = values[0];
    const std::int64_t raw_key_length = values[1];
    if ((operation != 0 && operation != 1) || raw_key_length < 0 ||
        raw_key_length > static_cast<std::int64_t>(max_key_length)) return -1;

    const std::size_t key_length = static_cast<std::size_t>(raw_key_length);
    const std::size_t text_length_index = 2 + key_length;
    if (length <= text_length_index) return -1;
    const std::int64_t raw_text_length = values[text_length_index];
    if (raw_text_length < 0 || raw_text_length > static_cast<std::int64_t>(max_text_length) ||
        (raw_text_length & 1) != 0) return -1;
    const std::size_t text_length = static_cast<std::size_t>(raw_text_length);
    if (length != text_length_index + 1 + text_length) return -1;

    std::uint8_t key[max_key_length]{};
    std::uint8_t text[max_text_length]{};
    for (std::size_t index = 0; index < key_length; ++index) {
        const std::int64_t value = values[2 + index];
        if (!is_letter(value)) return -1;
        key[index] = static_cast<std::uint8_t>(value);
    }
    for (std::size_t index = 0; index < text_length; ++index) {
        const std::int64_t value = values[text_length_index + 1 + index];
        if (!is_letter(value)) return -1;
        text[index] = static_cast<std::uint8_t>(value);
    }
    if (operation == 0) {
        for (std::size_t index = 0; index + 1 < text_length; ++index) {
            if (text[index] == text[index + 1]) return -1;
        }
    }

    std::uint8_t square[25]{};
    bool seen[128]{};
    std::size_t square_length = 0;
    for (std::size_t index = 0; index < key_length; ++index) {
        add_square_letter(square, seen, square_length, key[index]);
    }
    for (std::size_t index = 0; index < 25; ++index) {
        add_square_letter(square, seen, square_length,
                          static_cast<std::uint8_t>(alphabet[index]));
    }

    int position[128];
    for (std::size_t index = 0; index < 128; ++index) position[index] = -1;
    for (std::size_t index = 0; index < square_length; ++index) {
        position[square[index]] = static_cast<int>(index);
    }

    std::uint64_t hash = fnv_offset_basis;
    const int direction = operation == 0 ? 1 : -1;
    for (std::size_t index = 0; index < text_length; index += 2) {
        const int first = position[text[index]];
        const int second = position[text[index + 1]];
        const int row1 = first / 5;
        const int column1 = first % 5;
        const int row2 = second / 5;
        const int column2 = second % 5;
        std::uint8_t output_first;
        std::uint8_t output_second;

        if (row1 == row2) {
            const int next_column1 = (column1 + direction + 5) % 5;
            const int next_column2 = (column2 + direction + 5) % 5;
            output_first = square[row1 * 5 + next_column1];
            output_second = square[row2 * 5 + next_column2];
        } else if (column1 == column2) {
            const int next_row1 = (row1 + direction + 5) % 5;
            const int next_row2 = (row2 + direction + 5) % 5;
            output_first = square[next_row1 * 5 + column1];
            output_second = square[next_row2 * 5 + column2];
        } else {
            output_first = square[row1 * 5 + column2];
            output_second = square[row2 * 5 + column1];
        }

        hash = hash_byte(hash, output_first);
        hash = hash_byte(hash, output_second);
    }

    return static_cast<std::int64_t>(hash & low_63_mask);
}
