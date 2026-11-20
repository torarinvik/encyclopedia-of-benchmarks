/* Evaluate a bounded token expression with Pratt binding powers. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = INT64_MIN;
constexpr std::size_t max_tokens = 15;

struct PrattParser {
    const std::int64_t *input;
    std::size_t count;
    std::size_t position;
    bool invalid;
};

std::int64_t parse_expression(PrattParser &parser, std::int64_t minimum_binding_power)
{
    if (parser.position >= parser.count) {
        parser.invalid = true;
        return 0;
    }
    const std::size_t offset = 1 + 2 * parser.position++;
    const std::int64_t kind = parser.input[offset];
    std::int64_t left;
    if (kind == 1) {
        left = parser.input[offset + 1];
    } else if (kind == 3) {
        left = -parse_expression(parser, 25);
    } else if (kind == 5) {
        left = parse_expression(parser, 0);
        if (parser.invalid || parser.position >= parser.count ||
            parser.input[1 + 2 * parser.position] != 6) {
            parser.invalid = true;
            return 0;
        }
        ++parser.position;
    } else {
        parser.invalid = true;
        return 0;
    }
    if (parser.invalid) return 0;

    while (parser.position < parser.count) {
        const std::int64_t op = parser.input[1 + 2 * parser.position];
        const std::int64_t binding_power = (op == 2 || op == 3) ? 10 : (op == 4 ? 20 : -1);
        if (binding_power < minimum_binding_power) break;
        ++parser.position;
        const std::int64_t right = parse_expression(parser, binding_power + 1);
        if (parser.invalid) return 0;
        if (op == 2) left += right;
        else if (op == 3) left -= right;
        else left *= right;
    }
    return left;
}
}

extern "C" std::int64_t pratt_expression_evaluation(const std::int64_t *input,
                                                       std::size_t length) noexcept
{
    if (input == nullptr || length < 1 || length > 32) return invalid_result;
    const std::int64_t count_value = input[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_tokens)) return invalid_result;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return invalid_result;
    for (std::size_t token = 0; token < count; ++token) {
        const std::int64_t kind = input[1 + 2 * token];
        const std::int64_t payload = input[2 + 2 * token];
        if (kind == 1) {
            if (payload < 0 || payload > 9) return invalid_result;
        } else if (kind >= 2 && kind <= 6) {
            if (payload != 0) return invalid_result;
        } else {
            return invalid_result;
        }
    }
    PrattParser parser{input, count, 0, false};
    const std::int64_t result = parse_expression(parser, 0);
    if (parser.invalid || parser.position != count) return invalid_result;
    return result;
}
