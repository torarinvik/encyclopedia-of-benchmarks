#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxSequenceLength = 16;
constexpr std::size_t MaxParseableInputLength = 38;
constexpr std::size_t ScoreStride = 17;
}

extern "C" std::int64_t smith_waterman_java(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 5 || length > MaxParseableInputLength) return -1;
    const auto query_length_value = input[0];
    const auto subject_length_value = input[1];
    const auto match_score = input[2];
    const auto mismatch_score = input[3];
    const auto gap_score = input[4];
    if (query_length_value < 0 || query_length_value > static_cast<std::int64_t>(MaxSequenceLength) ||
        subject_length_value < 0 || subject_length_value > static_cast<std::int64_t>(MaxSequenceLength) ||
        match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
        gap_score < -5 || gap_score > -1) return -1;
    const auto query_length = static_cast<std::size_t>(query_length_value);
    const auto subject_length = static_cast<std::size_t>(subject_length_value);
    if (length != 5 + query_length + subject_length) return -1;
    for (std::size_t index = 5; index < length; ++index) {
        const auto value = input[index];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == '-')) return -1;
    }

    std::int64_t scores[ScoreStride * ScoreStride]{};
    std::int64_t maximum = 0;
    for (std::size_t row = 1; row <= query_length; ++row) {
        for (std::size_t column = 1; column <= subject_length; ++column) {
            const auto query_char = input[4 + row];
            const auto subject_char = input[4 + query_length + column];
            const auto pair_score = query_char == subject_char ? match_score : mismatch_score;
            const auto diagonal = scores[(row - 1) * ScoreStride + column - 1] + pair_score;
            const auto above = scores[(row - 1) * ScoreStride + column] + gap_score;
            const auto left = scores[row * ScoreStride + column - 1] + gap_score;
            auto value = diagonal;
            if (above > value) value = above;
            if (left > value) value = left;
            if (value < 0) value = 0;
            scores[row * ScoreStride + column] = value;
            if (value > maximum) maximum = value;
        }
    }
    return maximum;
}
