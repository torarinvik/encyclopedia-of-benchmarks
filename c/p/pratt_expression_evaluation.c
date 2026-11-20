/* Evaluate a bounded token expression with Pratt binding powers. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_TOKENS 15

typedef struct {
    const int64_t *input;
    size_t count;
    size_t position;
    bool invalid;
} PrattParser;

static int64_t parse_expression(PrattParser *parser, int64_t minimum_binding_power)
{
    if (parser->position >= parser->count) {
        parser->invalid = true;
        return 0;
    }

    const size_t offset = 1 + 2 * parser->position++;
    const int64_t kind = parser->input[offset];
    int64_t left;
    if (kind == 1) {
        left = parser->input[offset + 1];
    } else if (kind == 3) {
        left = -parse_expression(parser, 25);
    } else if (kind == 5) {
        left = parse_expression(parser, 0);
        if (parser->invalid || parser->position >= parser->count ||
            parser->input[1 + 2 * parser->position] != 6) {
            parser->invalid = true;
            return 0;
        }
        ++parser->position;
    } else {
        parser->invalid = true;
        return 0;
    }
    if (parser->invalid) return 0;

    while (parser->position < parser->count) {
        const int64_t op = parser->input[1 + 2 * parser->position];
        const int64_t binding_power = (op == 2 || op == 3) ? 10 : (op == 4 ? 20 : -1);
        if (binding_power < minimum_binding_power) break;
        ++parser->position;
        const int64_t right = parse_expression(parser, binding_power + 1);
        if (parser->invalid) return 0;
        if (op == 2) left += right;
        else if (op == 3) left -= right;
        else left *= right;
    }
    return left;
}

int64_t pratt_expression_evaluation(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 32) return INVALID_RESULT;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_TOKENS) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return INVALID_RESULT;

    for (size_t token = 0; token < count; ++token) {
        const int64_t kind = input[1 + 2 * token];
        const int64_t payload = input[2 + 2 * token];
        if (kind == 1) {
            if (payload < 0 || payload > 9) return INVALID_RESULT;
        } else if (kind >= 2 && kind <= 6) {
            if (payload != 0) return INVALID_RESULT;
        } else {
            return INVALID_RESULT;
        }
    }

    PrattParser parser = {input, count, 0, false};
    const int64_t result = parse_expression(&parser, 0);
    if (parser.invalid || parser.position != count) return INVALID_RESULT;
    return result;
}
