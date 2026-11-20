module pratt_expression_evaluation;

const long INVALID_RESULT = -9223372036854775807L - 1L;
const usz MAX_TOKENS = 15;

struct PrattParser {
    long* input;
    usz count;
    usz position;
    bool invalid;
}

fn long parse_expression(PrattParser* parser, long minimum_binding_power)
{
    if (parser.position >= parser.count) {
        parser.invalid = true;
        return 0;
    }
    usz offset = 1 + 2 * parser.position;
    parser.position++;
    long kind = parser.input[offset];
    long left;
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
        parser.position++;
    } else {
        parser.invalid = true;
        return 0;
    }
    if (parser.invalid) return 0;

    while (parser.position < parser.count) {
        long op = parser.input[1 + 2 * parser.position];
        long binding_power = (op == 2 || op == 3) ? 10 : (op == 4 ? 20 : -1);
        if (binding_power < minimum_binding_power) break;
        parser.position++;
        long right = parse_expression(parser, binding_power + 1);
        if (parser.invalid) return 0;
        if (op == 2) { left += right; }
        else if (op == 3) { left -= right; }
        else { left *= right; }
    }
    return left;
}

fn long pratt_expression_evaluation(long* input, usz length) @export("pratt_expression_evaluation")
{
    if (input == null || length < 1 || length > 32) return INVALID_RESULT;
    long count_value = input[0];
    if (count_value < 1 || count_value > MAX_TOKENS) return INVALID_RESULT;
    usz count = count_value;
    if (length != 1 + 2 * count) return INVALID_RESULT;
    for (usz token = 0; token < count; token++) {
        long kind = input[1 + 2 * token];
        long payload = input[2 + 2 * token];
        if (kind == 1) {
            if (payload < 0 || payload > 9) return INVALID_RESULT;
        } else if (kind >= 2 && kind <= 6) {
            if (payload != 0) return INVALID_RESULT;
        } else {
            return INVALID_RESULT;
        }
    }
    PrattParser parser = {input, count, 0, false};
    long result = parse_expression(&parser, 0);
    if (parser.invalid || parser.position != count) return INVALID_RESULT;
    return result;
}
