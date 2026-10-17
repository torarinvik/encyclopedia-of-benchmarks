const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT_VALUES: usize = 257;
const MAX_EXPRESSION_BYTES: i64 = 255;
const MAX_OPERANDS: usize = 16;
const MAX_OPERATORS: usize = 15;
const MAX_LITERAL_BYTES: usize = 16;
const MAX_LITERAL_VALUE: f64 = 1_000_000.0;
const MAX_INTERMEDIATE: f64 = 1_000_000_000_000.0;

noinline fn roundedMultiply(left: f64, right: f64) f64 { return left * right; }
noinline fn roundedAdd(left: f64, right: f64) f64 { return left + right; }
noinline fn roundedDivide(left: f64, right: f64) f64 { return left / right; }

fn precedence(operator: u8) u8 {
    return switch (operator) { '^' => 3, '*' , '/' => 2, else => 1 };
}

fn applyOperator(numbers: *[MAX_OPERANDS]f64, number_count: *usize, operator: u8) bool {
    if (number_count.* < 2) return false;
    number_count.* -= 1;
    const right = numbers[number_count.*];
    number_count.* -= 1;
    const left = numbers[number_count.*];
    const result = switch (operator) {
        '+' => left + right,
        '-' => left - right,
        '*' => left * right,
        '/' => blk: { if (right == 0.0) return false; break :blk left / right; },
        '^' => std.math.pow(f64, left, right),
        else => return false,
    };
    if (!std.math.isFinite(result) or @abs(result) > MAX_INTERMEDIATE) return false;
    numbers[number_count.*] = result;
    number_count.* += 1;
    return true;
}

export fn shunting_yard(input: [*c]const i64, length: usize) f64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return INVALID_RESULT;
    const byte_count_value = input[0];
    if (byte_count_value < 1 or byte_count_value > MAX_EXPRESSION_BYTES) return INVALID_RESULT;
    const byte_count: usize = @intCast(byte_count_value);
    if (length != byte_count + 1) return INVALID_RESULT;

    var numbers: [MAX_OPERANDS]f64 = [_]f64{0.0} ** MAX_OPERANDS;
    var operators: [MAX_OPERATORS]u8 = [_]u8{0} ** MAX_OPERATORS;
    var number_count: usize = 0;
    var operator_count: usize = 0;
    var operand_count: usize = 0;
    var seen_operator_count: usize = 0;
    var position: usize = 0;
    var expect_number = true;
    while (position < byte_count) {
        const raw = input[position + 1];
        if (raw < 0 or raw > 127) return INVALID_RESULT;
        const character: u8 = @intCast(raw);
        if (character == ' ' or (character >= 9 and character <= 13)) {
            position += 1;
            continue;
        }
        if (expect_number) {
            const start = position;
            var integer_digits: usize = 0;
            var number: f64 = 0.0;
            while (position < byte_count) {
                const digit = input[position + 1];
                if (digit < 48 or digit > 57) break;
                number = roundedAdd(roundedMultiply(number, 10.0),
                    @as(f64, @floatFromInt(digit - 48)));
                integer_digits += 1;
                position += 1;
            }
            if (integer_digits == 0) return INVALID_RESULT;
            if (position < byte_count and input[position + 1] == 46) {
                position += 1;
                var fraction_digits: usize = 0;
                var scale: f64 = 0.1;
                while (position < byte_count) {
                    const digit = input[position + 1];
                    if (digit < 48 or digit > 57) break;
                    const product = roundedMultiply(@as(f64, @floatFromInt(digit - 48)), scale);
                    number = roundedAdd(number, product);
                    scale = roundedDivide(scale, 10.0);
                    fraction_digits += 1;
                    position += 1;
                }
                if (fraction_digits == 0) return INVALID_RESULT;
            }
            if (position - start > MAX_LITERAL_BYTES or number > MAX_LITERAL_VALUE or operand_count >= MAX_OPERANDS)
                return INVALID_RESULT;
            numbers[number_count] = number;
            number_count += 1;
            operand_count += 1;
            expect_number = false;
        } else {
            if (character != '+' and character != '-' and character != '*' and character != '/' and character != '^')
                return INVALID_RESULT;
            while (operator_count > 0) {
                const top = operators[operator_count - 1];
                const top_precedence = precedence(top);
                const current_precedence = precedence(character);
                if (top_precedence < current_precedence or
                    (top_precedence == current_precedence and character == '^')) break;
                operator_count -= 1;
                if (!applyOperator(&numbers, &number_count, top)) return INVALID_RESULT;
            }
            if (operator_count >= MAX_OPERATORS) return INVALID_RESULT;
            operators[operator_count] = character;
            operator_count += 1;
            seen_operator_count += 1;
            position += 1;
            expect_number = true;
        }
    }
    if (expect_number or operand_count == 0 or seen_operator_count + 1 != operand_count)
        return INVALID_RESULT;
    while (operator_count > 0) {
        operator_count -= 1;
        if (!applyOperator(&numbers, &number_count, operators[operator_count])) return INVALID_RESULT;
    }
    if (number_count != 1) return INVALID_RESULT;
    return numbers[0];
}
