#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 64;
constexpr std::size_t max_parseable_input_values = 66;
constexpr std::size_t ascii_symbol_count = 128;
constexpr std::size_t max_symbols = 10;
constexpr std::size_t max_code_length = max_symbols - 1;
constexpr std::size_t max_output_bytes = 1 + max_symbols * (2 + max_code_length);

bool assign_codes(const std::array<std::uint8_t, max_symbols>& symbols,
                  const std::array<std::size_t, ascii_symbol_count>& frequencies,
                  std::size_t start, std::size_t end, std::size_t depth,
                  std::array<std::uint8_t, max_code_length>& prefix,
                  std::array<std::array<std::uint8_t, max_code_length>, ascii_symbol_count>& code_bits,
                  std::array<std::uint8_t, ascii_symbol_count>& code_lengths) noexcept
{
    if (start == end) {
        const std::uint8_t symbol = symbols[start];
        for (std::size_t index = 0; index < depth; ++index) {
            code_bits[symbol][index] = prefix[index];
        }
        code_lengths[symbol] = static_cast<std::uint8_t>(depth);
        return true;
    }
    if (depth >= max_code_length) return false;

    std::size_t total_frequency = 0;
    for (std::size_t index = start; index <= end; ++index) {
        total_frequency += frequencies[symbols[index]];
    }

    std::size_t left_sum = 0;
    std::size_t best_difference = static_cast<std::size_t>(-1);
    std::size_t split_index = start;
    for (std::size_t index = start; index < end; ++index) {
        left_sum += frequencies[symbols[index]];
        const std::size_t right_sum = total_frequency - left_sum;
        const std::size_t difference = left_sum > right_sum ? left_sum - right_sum : right_sum - left_sum;
        if (difference < best_difference) {
            best_difference = difference;
            split_index = index;
        }
    }

    prefix[depth] = static_cast<std::uint8_t>('0');
    if (!assign_codes(symbols, frequencies, start, split_index, depth + 1,
                      prefix, code_bits, code_lengths)) return false;
    prefix[depth] = static_cast<std::uint8_t>('1');
    return assign_codes(symbols, frequencies, split_index + 1, end, depth + 1,
                        prefix, code_bits, code_lengths);
}
} // namespace

extern "C" std::int64_t shannon_fano_generate_codes(const std::int64_t* input,
                                                     std::size_t input_length,
                                                     std::uint8_t* output,
                                                     std::size_t output_capacity) noexcept
{
    if (input_length > max_parseable_input_values) return -1;
    if (input == nullptr) {
        if (input_length != 0) return -1;
    } else {
        if (input_length == 0) return -1;
    }

    std::array<std::size_t, ascii_symbol_count> frequencies{};
    if (input != nullptr) {
        if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_length)) return -1;
        const std::size_t text_length = static_cast<std::size_t>(input[0]);
        if (input_length != 1 + text_length) return -1;
        for (std::size_t index = 0; index < text_length; ++index) {
            const std::int64_t code = input[1 + index];
            if (code < 0 || code >= static_cast<std::int64_t>(ascii_symbol_count)) return -1;
            ++frequencies[static_cast<std::size_t>(code)];
        }
    }

    std::array<std::uint8_t, max_symbols> symbols{};
    std::size_t symbol_count = 0;
    std::array<bool, max_text_length + 1> seen_frequency{};
    for (std::size_t symbol = 0; symbol < ascii_symbol_count; ++symbol) {
        const std::size_t frequency = frequencies[symbol];
        if (frequency == 0) continue;
        if (frequency > max_text_length || seen_frequency[frequency] || symbol_count >= max_symbols) return -1;
        seen_frequency[frequency] = true;
        symbols[symbol_count++] = static_cast<std::uint8_t>(symbol);
    }

    /* Unique frequencies make the source's descending order unambiguous. */
    for (std::size_t index = 1; index < symbol_count; ++index) {
        const std::uint8_t symbol = symbols[index];
        std::size_t position = index;
        while (position > 0 && frequencies[symbols[position - 1]] < frequencies[symbol]) {
            symbols[position] = symbols[position - 1];
            --position;
        }
        symbols[position] = symbol;
    }

    std::array<std::array<std::uint8_t, max_code_length>, ascii_symbol_count> code_bits{};
    std::array<std::uint8_t, ascii_symbol_count> code_lengths{};
    if (symbol_count == 1) {
        code_bits[symbols[0]][0] = static_cast<std::uint8_t>('0');
        code_lengths[symbols[0]] = 1;
    } else if (symbol_count > 1) {
        std::array<std::uint8_t, max_code_length> prefix{};
        if (!assign_codes(symbols, frequencies, 0, symbol_count - 1, 0,
                          prefix, code_bits, code_lengths)) return -1;
    }

    std::array<std::uint8_t, max_output_bytes> staged{};
    std::size_t staged_length = 0;
    staged[staged_length++] = static_cast<std::uint8_t>(symbol_count);
    for (std::size_t symbol = 0; symbol < ascii_symbol_count; ++symbol) {
        const std::uint8_t code_length = code_lengths[symbol];
        if (code_length == 0) continue;
        staged[staged_length++] = static_cast<std::uint8_t>(symbol);
        staged[staged_length++] = code_length;
        for (std::size_t index = 0; index < static_cast<std::size_t>(code_length); ++index) {
            staged[staged_length++] = code_bits[symbol][index];
        }
    }

    if (output == nullptr || output_capacity < staged_length) return -2;
    for (std::size_t index = 0; index < staged_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(staged_length);
}
