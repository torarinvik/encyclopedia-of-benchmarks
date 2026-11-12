#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_SEQUENCE_LENGTH = 64;
constexpr std::size_t MAX_INPUT_LENGTH = 132;

struct HirschbergState {
    std::int32_t forward[MAX_SEQUENCE_LENGTH + 1]{};
    std::int32_t backward[MAX_SEQUENCE_LENGTH + 1]{};
    std::uint8_t result[MAX_SEQUENCE_LENGTH]{};
    std::size_t result_length = 0;
};

void lcs_row(const std::int64_t *a, std::size_t a0, std::size_t a1,
             const std::int64_t *b, std::size_t b0, std::size_t b1,
             bool reverse_a, bool reverse_b, std::int32_t *row) noexcept
{
    const std::size_t width = b1 - b0;
    for (std::size_t j = 0; j <= width; ++j) row[j] = 0;
    for (std::size_t i = 0; i < a1 - a0; ++i) {
        const auto av = reverse_a ? a[a1 - 1 - i] : a[a0 + i];
        std::int32_t diagonal = 0;
        for (std::size_t j = 1; j <= width; ++j) {
            const std::int32_t above = row[j];
            const auto bv = reverse_b ? b[b1 - j] : b[b0 + j - 1];
            if (av == bv) row[j] = diagonal + 1;
            else if (row[j - 1] > row[j]) row[j] = row[j - 1];
            diagonal = above;
        }
    }
}

void recover_lcs(const std::int64_t *a, std::size_t a0, std::size_t a1,
                 const std::int64_t *b, std::size_t b0, std::size_t b1,
                 HirschbergState &state)
{
    const std::size_t a_length = a1 - a0;
    const std::size_t b_length = b1 - b0;
    if (a_length == 0 || b_length == 0) return;
    if (a_length == 1) {
        for (std::size_t j = b0; j < b1; ++j) {
            if (a[a0] == b[j]) {
                state.result[state.result_length++] = static_cast<std::uint8_t>(a[a0]);
                return;
            }
        }
        return;
    }

    const std::size_t middle = a0 + a_length / 2;
    lcs_row(a, a0, middle, b, b0, b1, false, false, state.forward);
    lcs_row(a, middle, a1, b, b0, b1, true, true, state.backward);
    std::size_t split = 0;
    std::int32_t best_score = -1;
    for (std::size_t j = 0; j <= b_length; ++j) {
        const auto score = state.forward[j] + state.backward[b_length - j];
        if (score > best_score) {
            best_score = score;
            split = j;
        }
    }
    recover_lcs(a, a0, middle, b, b0, b0 + split, state);
    recover_lcs(a, middle, a1, b, b0 + split, b1, state);
}
}

extern "C" std::int64_t hirschberg_lcs(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_SEQUENCE_LENGTH)
        || input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_SEQUENCE_LENGTH)) return -1;
    const auto first_length = static_cast<std::size_t>(input[0]);
    const auto second_length = static_cast<std::size_t>(input[1]);
    if (length != 2 + first_length + second_length) return -1;
    const auto *first = input + 2;
    const auto *second = first + first_length;
    for (std::size_t i = 0; i < first_length + second_length; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;

    HirschbergState state{};
    const std::int64_t *a = first;
    const std::int64_t *b = second;
    auto a_length = first_length;
    auto b_length = second_length;
    if (a_length < b_length) {
        a = second;
        b = first;
        a_length = second_length;
        b_length = first_length;
    }
    recover_lcs(a, 0, a_length, b, 0, b_length, state);
    if (output == nullptr || capacity < state.result_length) return -2;
    for (std::size_t i = 0; i < state.result_length; ++i) output[i] = state.result[i];
    return static_cast<std::int64_t>(state.result_length);
}
