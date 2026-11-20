#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_side = 12;
constexpr std::size_t max_cells = max_side * max_side;
constexpr std::size_t max_parseable_input_length = 2 + 2 * max_cells + 1;

std::uint16_t sample_code(const std::int64_t* input, std::size_t base,
                          std::size_t side, std::size_t row,
                          std::size_t column, std::size_t q,
                          std::size_t stride) {
    std::uint16_t code = 0;
    for (std::size_t step = 0; step < q; ++step) {
        const auto at = base + row * side + column + step * stride;
        code = static_cast<std::uint16_t>(4 * code + input[at]);
    }
    return code;
}

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}  // namespace

extern "C" std::int64_t two_dimensional_k_mismatch_linear_templates(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_parseable_input_length) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    if (n_value < 3 || n_value > static_cast<std::int64_t>(max_side) ||
        m_value < 3 || m_value > n_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    const auto text_size = n * n;
    const auto pattern_size = m * m;
    if (length != 2 + text_size + pattern_size) return -1;
    const auto pattern_base = 2 + text_size;
    for (std::size_t index = 0; index < text_size + pattern_size; ++index)
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;

    std::size_t q = 1;
    std::size_t code_capacity = 4;
    while (code_capacity < pattern_size) {
        ++q;
        code_capacity *= 4;
    }
    const auto stride = m / q;
    const auto final_offset = (q - 1) * stride;
    std::array<std::int16_t, 256> heads{};
    heads.fill(-1);
    std::array<std::int16_t, max_cells> next{};
    std::array<std::uint8_t, max_cells> sample_row{};
    std::array<std::uint8_t, max_cells> sample_column{};
    std::size_t sample_count = 0;
    for (std::size_t row = 0; row < m; ++row) {
        for (std::size_t residue = 0; residue < stride; ++residue) {
            const auto code = sample_code(input, pattern_base, m, row, residue, q, stride);
            sample_row[sample_count] = static_cast<std::uint8_t>(row);
            sample_column[sample_count] = static_cast<std::uint8_t>(residue);
            next[sample_count] = heads[code];
            heads[code] = static_cast<std::int16_t>(sample_count++);
        }
    }

    std::array<bool, max_cells> considered{};
    std::array<bool, max_cells> matched{};
    const auto starts = n - m + 1;
    for (std::size_t text_row = 0; text_row < n; ++text_row) {
        if (text_row % m < m - 2) continue;
        for (std::size_t text_column = 0;
             text_column + final_offset < n; text_column += stride) {
            const auto code = sample_code(input, 2, n, text_row, text_column, q, stride);
            auto address = heads[code];
            while (address >= 0) {
                const auto slot = static_cast<std::size_t>(address);
                const auto candidate_row = static_cast<std::int64_t>(text_row) - sample_row[slot];
                const auto candidate_column = static_cast<std::int64_t>(text_column) - sample_column[slot];
                if (candidate_row >= 0 && candidate_column >= 0 &&
                    static_cast<std::size_t>(candidate_row) < starts &&
                    static_cast<std::size_t>(candidate_column) < starts) {
                    const auto candidate = static_cast<std::size_t>(candidate_row) * n +
                                           static_cast<std::size_t>(candidate_column);
                    if (!considered[candidate]) {
                        considered[candidate] = true;
                        std::size_t mismatches = 0;
                        for (std::size_t row = 0; row < m && mismatches < 2; ++row) {
                            for (std::size_t column = 0; column < m; ++column) {
                                const auto text_at = 2 +
                                    (static_cast<std::size_t>(candidate_row) + row) * n +
                                    static_cast<std::size_t>(candidate_column) + column;
                                const auto pattern_at = pattern_base + row * m + column;
                                if (input[text_at] != input[pattern_at] && ++mismatches == 2)
                                    break;
                            }
                        }
                        matched[candidate] = mismatches <= 1;
                    }
                }
                address = next[slot];
            }
        }
    }

    std::size_t match_count = 0;
    for (std::size_t row = 0; row < starts; ++row)
        for (std::size_t column = 0; column < starts; ++column)
            if (matched[row * n + column]) ++match_count;
    const auto output_bytes = 8 * (1 + 2 * match_count);
    if (output == nullptr || capacity < output_bytes) return -2;
    put_i64_le(output, 0, static_cast<std::int64_t>(match_count));
    std::size_t word = 1;
    for (std::size_t row = 0; row < starts; ++row) {
        for (std::size_t column = 0; column < starts; ++column) {
            if (!matched[row * n + column]) continue;
            put_i64_le(output, 8 * word++, static_cast<std::int64_t>(row));
            put_i64_le(output, 8 * word++, static_cast<std::int64_t>(column));
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
