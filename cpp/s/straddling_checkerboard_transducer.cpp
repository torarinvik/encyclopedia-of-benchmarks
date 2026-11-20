#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxInput = 97;
constexpr std::size_t MaxText = 64;
constexpr int BoardSize = 30;
constexpr int MaxOutput = 128;

bool parse_board(const std::int64_t* input, std::size_t length, int& hole_a,
                 int& hole_b, std::int64_t& text_length, std::int64_t& mode) noexcept {
    if (input == nullptr || length < 32 || length > MaxInput) return false;
    mode = input[0];
    if (mode != 0 && mode != 1) return false;
    int holes = 0;
    for (int position = 0; position < BoardSize; ++position) {
        const auto value = input[1 + position];
        if (position < 10 && value == 0) {
            if (holes == 0) hole_a = position;
            else if (holes == 1) hole_b = position;
            ++holes;
            continue;
        }
        if (value < 32 || value > 126) return false;
        for (int prior = 0; prior < position; ++prior)
            if (input[1 + prior] == value) return false;
    }
    if (holes != 2) return false;
    text_length = input[31];
    if (text_length < 0 || text_length > static_cast<std::int64_t>(MaxText)) return false;
    return length == static_cast<std::size_t>(32 + text_length);
}

int find_symbol(const std::int64_t* input, std::int64_t value) noexcept {
    for (int position = 0; position < BoardSize; ++position)
        if (input[1 + position] != 0 && input[1 + position] == value) return position;
    return -1;
}

bool measure_decode(const std::int64_t* input, std::int64_t text_length,
                    int hole_a, int hole_b, int& result_length) noexcept {
    result_length = 0;
    for (std::int64_t i = 0; i < text_length; ++i) {
        const auto value = input[32 + i];
        if (value < '0' || value > '9') return false;
        const int column = static_cast<int>(value - '0');
        if (input[1 + column] != 0) {
            ++result_length;
            continue;
        }
        if (i + 1 >= text_length) return false;
        const auto next = input[32 + i + 1];
        if (next < '0' || next > '9') return false;
        if (column != hole_a && column != hole_b) return false;
        ++result_length;
        ++i;
    }
    return true;
}
} // namespace

extern "C" std::int64_t straddling_checkerboard_transducer(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t output_capacity) noexcept {
    int hole_a = -1, hole_b = -1;
    std::int64_t text_length = 0, mode = -1;
    if (!parse_board(input, length, hole_a, hole_b, text_length, mode)) return -1;

    int result_length = 0;
    if (mode == 0) {
        for (std::int64_t i = 0; i < text_length; ++i) {
            const int position = find_symbol(input, input[32 + i]);
            if (position < 0) return -1;
            result_length += position < 10 ? 1 : 2;
        }
    } else if (!measure_decode(input, text_length, hole_a, hole_b, result_length)) {
        return -1;
    }

    if (result_length > MaxOutput) return -1;
    if (output == nullptr || output_capacity < static_cast<std::size_t>(result_length)) return -2;

    if (mode == 0) {
        std::size_t out = 0;
        for (std::int64_t i = 0; i < text_length; ++i) {
            const int position = find_symbol(input, input[32 + i]);
            if (position < 10) {
                output[out++] = static_cast<std::uint8_t>('0' + position);
            } else {
                const int row_digit = position < 20 ? hole_a : hole_b;
                output[out++] = static_cast<std::uint8_t>('0' + row_digit);
                output[out++] = static_cast<std::uint8_t>('0' + position % 10);
            }
        }
    } else {
        std::size_t out = 0;
        for (std::int64_t i = 0; i < text_length; ++i) {
            const int column = static_cast<int>(input[32 + i] - '0');
            if (input[1 + column] != 0) {
                output[out++] = static_cast<std::uint8_t>(input[1 + column]);
            } else {
                const int row = column == hole_a ? 1 : 2;
                const int next_column = static_cast<int>(input[32 + ++i] - '0');
                output[out++] = static_cast<std::uint8_t>(input[1 + row * 10 + next_column]);
            }
        }
    }
    return result_length;
}
