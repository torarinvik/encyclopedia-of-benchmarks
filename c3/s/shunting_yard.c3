module shunting_yard;

extern fn double pow(double base, double exponent);

const double INVALID_RESULT = -1.0e300;
const usz MAX_INPUT_VALUES = 257;
const long MAX_EXPRESSION_BYTES = 255;
const usz MAX_OPERANDS = 16;
const usz MAX_OPERATORS = 15;
const usz MAX_LITERAL_BYTES = 16;
const double MAX_LITERAL_VALUE = 1000000.0;
const double MAX_INTERMEDIATE = 1000000000000.0;

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn bool is_ascii_whitespace(long value) {
    return value == ' ' || value == '\t' || value == '\n' ||
           value == '\v' || value == '\f' || value == '\r';
}

fn bool is_ascii_digit(long value) {
    return value >= '0' && value <= '9';
}

fn bool is_operator(long value) {
    return value == '+' || value == '-' || value == '*' ||
           value == '/' || value == '^';
}

fn int precedence(char operator) {
    if (operator == '^') return 3;
    if (operator == '*' || operator == '/') return 2;
    return 1;
}

fn bool apply_top(double* numbers, usz* number_count,
                  char* operators, usz* operator_count) {
    if (*number_count < 2 || *operator_count == 0) return false;
    *operator_count = *operator_count - 1;
    char operator = operators[*operator_count];
    *number_count = *number_count - 1;
    double right = numbers[*number_count];
    *number_count = *number_count - 1;
    double left = numbers[*number_count];
    double value;

    if (operator == '+') value = left + right;
    else if (operator == '-') value = left - right;
    else if (operator == '*') value = left * right;
    else if (operator == '/') {
        if (right == 0.0) return false;
        value = left / right;
    } else if (operator == '^') value = pow(left, right);
    else return false;

    if (value != value || value < -MAX_INTERMEDIATE || value > MAX_INTERMEDIATE)
        return false;
    numbers[*number_count] = value;
    *number_count = *number_count + 1;
    return true;
}

fn double shunting_yard(long* input, usz length) @export("shunting_yard") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > MAX_EXPRESSION_BYTES) return INVALID_RESULT;
    usz byte_count = (usz)input[0];
    if (length != byte_count + 1) return INVALID_RESULT;
    for (usz index = 0; index < byte_count; index++) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return INVALID_RESULT;
    }

    double numbers[MAX_OPERANDS] = {0.0};
    char operators[MAX_OPERATORS] = {0};
    usz number_count = 0;
    usz operator_count = 0;
    usz operand_count = 0;
    usz parsed_operator_count = 0;
    usz position = 1;
    bool expect_number = true;

    while (position <= byte_count) {
        while (position <= byte_count && is_ascii_whitespace(input[position])) position++;
        if (position > byte_count) break;

        if (expect_number) {
            usz start = position;
            usz integer_digits = 0;
            double value = 0.0;
            while (position <= byte_count && is_ascii_digit(input[position])) {
                value = rounded_add(rounded_multiply(value, 10.0),
                                    (double)(input[position] - '0'));
                integer_digits++;
                position++;
            }
            if (integer_digits == 0) return INVALID_RESULT;
            if (position <= byte_count && input[position] == '.') {
                position++;
                usz fractional_digits = 0;
                double scale = 0.1;
                while (position <= byte_count && is_ascii_digit(input[position])) {
                    double term = rounded_multiply(
                        (double)(input[position] - '0'), scale);
                    value = rounded_add(value, term);
                    scale = rounded_divide(scale, 10.0);
                    fractional_digits++;
                    position++;
                }
                if (fractional_digits == 0) return INVALID_RESULT;
            }
            usz literal_length = position - start;
            if (literal_length > MAX_LITERAL_BYTES || value < 0.0 ||
                value > MAX_LITERAL_VALUE || operand_count >= MAX_OPERANDS)
                return INVALID_RESULT;

            numbers[number_count] = value;
            number_count++;
            operand_count++;
            expect_number = false;
        } else {
            long raw_operator = input[position];
            if (!is_operator(raw_operator) || parsed_operator_count >= MAX_OPERATORS)
                return INVALID_RESULT;
            char current = (char)raw_operator;
            while (operator_count > 0) {
                char previous = operators[operator_count - 1];
                int previous_precedence = precedence(previous);
                int current_precedence = precedence(current);
                if (previous_precedence < current_precedence ||
                    (previous_precedence == current_precedence && current == '^')) break;
                if (!apply_top(numbers, &number_count, operators, &operator_count))
                    return INVALID_RESULT;
            }
            operators[operator_count] = current;
            operator_count++;
            parsed_operator_count++;
            position++;
            expect_number = true;
        }
    }

    if (expect_number || operand_count == 0 ||
        parsed_operator_count + 1 != operand_count) return INVALID_RESULT;
    while (operator_count > 0) {
        if (!apply_top(numbers, &number_count, operators, &operator_count))
            return INVALID_RESULT;
    }
    if (number_count != 1) return INVALID_RESULT;
    return numbers[0];
}
