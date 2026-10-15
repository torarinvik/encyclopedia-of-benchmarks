#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace {
constexpr std::size_t max_input = 2200;
constexpr std::size_t max_nodes = 127;

bool ascii_space(std::int64_t value) {
    return value == ' ' || (value >= '\t' && value <= '\r');
}

bool parse_integer(const std::int64_t *input, std::size_t first, std::size_t last, std::int32_t &result) {
    while (first < last && ascii_space(input[first])) ++first;
    while (last > first && ascii_space(input[last - 1])) --last;
    if (first == last) return false;
    bool negative = false;
    if (input[first] == '-' || input[first] == '+') { negative = input[first] == '-'; ++first; }
    if (first == last) return false;
    std::int64_t value = 0;
    const std::int64_t limit = negative ? INT64_C(2147483648) : INT64_C(2147483647);
    for (auto i = first; i < last; ++i) {
        if (input[i] < '0' || input[i] > '9') return false;
        const auto digit = input[i] - '0';
        if (value > (limit - digit) / 10) return false;
        value = value * 10 + digit;
    }
    result = static_cast<std::int32_t>(negative ? -value : value);
    return true;
}
}

extern "C" std::int64_t serialize_deserialize_binary_tree(const std::int64_t *values,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) {
    if (values == nullptr || length == 0 || length > max_input) return -1;
    for (std::size_t i = 0; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    std::vector<std::uint8_t> encoded;
    encoded.reserve(length);
    std::size_t position = 0, slots = 1, nodes = 0;
    while (position < length) {
        if (slots == 0) return -1;
        const auto start = position;
        while (position < length && values[position] != ',') ++position;
        const auto end = position;
        if (start == end) return -1;
        const bool is_null = end - start == 4 && values[start] == 'n' && values[start + 1] == 'u' &&
            values[start + 2] == 'l' && values[start + 3] == 'l';
        if (!encoded.empty()) encoded.push_back(',');
        if (is_null) encoded.insert(encoded.end(), {'n', 'u', 'l', 'l'});
        else {
            std::int32_t number;
            if (!parse_integer(values, start, end, number) || ++nodes > max_nodes) return -1;
            const std::string text = std::to_string(number);
            encoded.insert(encoded.end(), text.begin(), text.end());
        }
        --slots;
        if (!is_null) slots += 2;
        if (position < length && ++position == length) return -1;
    }
    if (slots != 0) return -1;
    if (output == nullptr || output_capacity < encoded.size()) return -2;
    for (std::size_t i = 0; i < encoded.size(); ++i) output[i] = encoded[i];
    return static_cast<std::int64_t>(encoded.size());
}
