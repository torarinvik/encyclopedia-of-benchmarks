const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const MAX_TOKENS: usize = 15;

const PrattParser = struct {
    input: [*c]const i64,
    count: usize,
    position: usize,
    invalid: bool,

    fn expression(self: *PrattParser, minimum_binding_power: i64) i64 {
        if (self.position >= self.count) {
            self.invalid = true;
            return 0;
        }
        const offset = 1 + 2 * self.position;
        self.position += 1;
        const kind = self.input[offset];
        var left: i64 = undefined;
        if (kind == 1) {
            left = self.input[offset + 1];
        } else if (kind == 3) {
            left = -self.expression(25);
        } else if (kind == 5) {
            left = self.expression(0);
            if (self.invalid or self.position >= self.count or
                self.input[1 + 2 * self.position] != 6) {
                self.invalid = true;
                return 0;
            }
            self.position += 1;
        } else {
            self.invalid = true;
            return 0;
        }
        if (self.invalid) return 0;

        while (self.position < self.count) {
            const operator = self.input[1 + 2 * self.position];
            const binding_power: i64 = if (operator == 2 or operator == 3) 10
                else if (operator == 4) 20 else -1;
            if (binding_power < minimum_binding_power) break;
            self.position += 1;
            const right = self.expression(binding_power + 1);
            if (self.invalid) return 0;
            if (operator == 2) left += right
            else if (operator == 3) left -= right
            else left *= right;
        }
        return left;
    }
};

export fn pratt_expression_evaluation(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 32) return INVALID_RESULT;
    const count_value = input[0];
    if (count_value < 1 or count_value > MAX_TOKENS) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return INVALID_RESULT;
    for (0..count) |token| {
        const kind = input[1 + 2 * token];
        const payload = input[2 + 2 * token];
        if (kind == 1) {
            if (payload < 0 or payload > 9) return INVALID_RESULT;
        } else if (kind >= 2 and kind <= 6) {
            if (payload != 0) return INVALID_RESULT;
        } else {
            return INVALID_RESULT;
        }
    }
    var parser = PrattParser{ .input = input, .count = count, .position = 0, .invalid = false };
    const result = parser.expression(0);
    if (parser.invalid or parser.position != count) return INVALID_RESULT;
    return result;
}
