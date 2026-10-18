#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_sequence_length = 16;
constexpr std::size_t max_parseable_input_length = 38;
constexpr std::size_t max_output_bytes = 1233;
constexpr std::size_t score_stride = 17;
constexpr std::size_t max_trace_steps = 2 * max_sequence_length;

bool is_ascii_letter_or_gap(std::int64_t value) noexcept {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == '-';
}

char uppercase_ascii(std::int64_t value) noexcept {
    if (value >= 'a' && value <= 'z') value -= ('a' - 'A');
    return static_cast<char>(value);
}

std::int32_t pair_score(char left, char right, std::int32_t match,
                        std::int32_t mismatch, std::int32_t gap) noexcept {
    if (left == '-' || right == '-') return gap;
    return left == right ? match : mismatch;
}

void write_u32_le(std::uint8_t *output, std::size_t offset, std::uint32_t value) noexcept {
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
}

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) noexcept {
    write_u32_le(output, offset, static_cast<std::uint32_t>(value));
}
}

extern "C" std::int64_t smith_waterman_rust(const std::int64_t *input,
    std::size_t input_length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 5 || input_length > max_parseable_input_length) return -1;
    const auto query_length_value = input[0];
    const auto subject_length_value = input[1];
    const auto match_value = input[2];
    const auto mismatch_value = input[3];
    const auto gap_value = input[4];
    if (query_length_value < 0 || query_length_value > static_cast<std::int64_t>(max_sequence_length) ||
        subject_length_value < 0 || subject_length_value > static_cast<std::int64_t>(max_sequence_length) ||
        match_value < 1 || match_value > 5 || mismatch_value < -5 || mismatch_value > -1 ||
        gap_value < -5 || gap_value > -1) return -1;
    const auto query_length = static_cast<std::size_t>(query_length_value);
    const auto subject_length = static_cast<std::size_t>(subject_length_value);
    if (input_length != 5 + query_length + subject_length || input_length > 37) return -1;
    for (std::size_t i = 5; i < input_length; ++i) if (!is_ascii_letter_or_gap(input[i])) return -1;

    char query[max_sequence_length];
    char subject[max_sequence_length];
    for (std::size_t i = 0; i < query_length; ++i) query[i] = uppercase_ascii(input[5 + i]);
    for (std::size_t i = 0; i < subject_length; ++i)
        subject[i] = uppercase_ascii(input[5 + query_length + i]);
    const auto rows = query_length + 1;
    const auto columns = subject_length + 1;
    const auto match = static_cast<std::int32_t>(match_value);
    const auto mismatch = static_cast<std::int32_t>(mismatch_value);
    const auto gap = static_cast<std::int32_t>(gap_value);
    std::int32_t scores[score_stride * score_stride] = {};
    std::int32_t maximum = 0;
    std::size_t max_row = 0, max_column = 0;
    for (std::size_t row = 1; row < rows; ++row) {
        for (std::size_t column = 1; column < columns; ++column) {
            const auto diagonal = scores[(row - 1) * score_stride + column - 1] +
                pair_score(query[row - 1], subject[column - 1], match, mismatch, gap);
            const auto above = scores[(row - 1) * score_stride + column] + gap;
            const auto left = scores[row * score_stride + column - 1] + gap;
            auto value = diagonal;
            if (above > value) value = above;
            if (left > value) value = left;
            if (value < 0) value = 0;
            scores[row * score_stride + column] = value;
            if (value > maximum) { maximum = value; max_row = row; max_column = column; }
        }
    }

    char reverse_query[max_trace_steps];
    char reverse_subject[max_trace_steps];
    std::size_t trace_steps = 0;
    std::size_t row = max_row, column = max_column;
    while (row > 0 && column > 0 && scores[row * score_stride + column] > 0) {
        const auto current = scores[row * score_stride + column];
        const auto diagonal = scores[(row - 1) * score_stride + column - 1] +
            pair_score(query[row - 1], subject[column - 1], match, mismatch, gap);
        if (current == diagonal) {
            reverse_query[trace_steps] = query[row - 1];
            reverse_subject[trace_steps] = subject[column - 1];
            --row; --column;
        } else if (current == scores[(row - 1) * score_stride + column] + gap) {
            reverse_query[trace_steps] = query[row - 1];
            reverse_subject[trace_steps] = '-';
            --row;
        } else {
            reverse_query[trace_steps] = '-';
            reverse_subject[trace_steps] = subject[column - 1];
            --column;
        }
        ++trace_steps;
    }

    std::uint8_t staged[max_output_bytes];
    write_u32_le(staged, 0, static_cast<std::uint32_t>(rows));
    write_u32_le(staged, 4, static_cast<std::uint32_t>(columns));
    std::size_t offset = 8;
    for (std::size_t r = 0; r < rows; ++r) {
        for (std::size_t c = 0; c < columns; ++c) {
            write_i32_le(staged, offset, scores[r * score_stride + c]);
            offset += 4;
        }
    }
    const auto alignment_length = trace_steps == 0 ? 0 : 2 * trace_steps + 1;
    write_u32_le(staged, offset, static_cast<std::uint32_t>(alignment_length));
    offset += 4;
    if (trace_steps > 0) {
        for (std::size_t i = 0; i < trace_steps; ++i)
            staged[offset++] = static_cast<std::uint8_t>(reverse_query[trace_steps - i - 1]);
        staged[offset++] = static_cast<std::uint8_t>('\n');
        for (std::size_t i = 0; i < trace_steps; ++i)
            staged[offset++] = static_cast<std::uint8_t>(reverse_subject[trace_steps - i - 1]);
    }
    const auto required = offset;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}
