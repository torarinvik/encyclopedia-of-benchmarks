#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 16384;

bool is_triangular_score(std::int64_t score) noexcept
{
    for (std::int64_t n = 1; n <= 100; ++n) {
        if (score == n * (n + 1) / 2) return true;
    }
    return false;
}
}

extern "C" std::int64_t solution42(const std::int64_t *input,
                                    std::size_t input_length) noexcept
{
    if (input_length > max_input_length) return -1;
    if (input_length == 0) return 0;
    if (input == nullptr) return -1;

    for (std::size_t i = 0; i < input_length; ++i) {
        if (input[i] < 0 || input[i] > 127) return -1;
    }

    std::size_t first_line_length = 0;
    while (first_line_length < input_length && input[first_line_length] != 10 &&
           input[first_line_length] != 13) {
        ++first_line_length;
    }

    std::int64_t count = 0;
    std::size_t token_start = 0;
    for (std::size_t position = 0; position <= first_line_length; ++position) {
        if (position == first_line_length || input[position] == ',') {
            std::size_t start = token_start;
            std::size_t end = position;
            while (start < end && input[start] == '"') ++start;
            while (end > start && input[end - 1] == '"') --end;

            std::int64_t score = 0;
            for (std::size_t i = start; i < end; ++i) score += input[i] - 64;
            if (is_triangular_score(score)) ++count;
            token_start = position + 1;
        }
    }
    return count;
}
