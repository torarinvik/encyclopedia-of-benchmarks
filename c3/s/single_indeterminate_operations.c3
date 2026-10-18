module single_indeterminate_operations;

extern fn double pow(double base, double exponent);

const usz MAX_DEGREE = 8;
const usz MAX_COEFFICIENTS = MAX_DEGREE + 1;
const usz MAX_INPUT_LENGTH = 22;
const usz MAX_OUTPUT_ELEMENTS = 2 * MAX_DEGREE + 1;

const long OP_ADD = 0;
const long OP_SUBTRACT = 1;
const long OP_MULTIPLY = 2;
const long OP_EVALUATE = 3;
const long OP_DERIVATIVE = 4;
const long OP_INTEGRAL = 5;

fn bool finite_value(double value) {
    return value == value && value >= -1.7976931348623157e308 &&
           value <= 1.7976931348623157e308;
}

fn bool exact_integer_in_range(double value, long minimum, long maximum, long* result) {
    if (!finite_value(value) || value < (double)minimum || value > (double)maximum) return false;
    long converted = (long)value;
    if ((double)converted != value) return false;
    *result = converted;
    return true;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn bool read_polynomial(double* values, usz length, usz* cursor, long* degree,
                        double* coefficients) {
    if (*cursor >= length || !exact_integer_in_range(values[*cursor], 0, (long)MAX_DEGREE, degree))
        return false;
    *cursor = *cursor + 1;

    usz count = (usz)(*degree + 1);
    if (*cursor > length || count > length - *cursor) return false;
    for (usz index = 0; index < count; index++) {
        double coefficient = values[*cursor + index];
        if (!finite_value(coefficient) || coefficient < -10.0 || coefficient > 10.0) return false;
        coefficients[index] = coefficient;
    }
    *cursor = *cursor + count;
    return true;
}

fn void add_polynomials(long degree_a, double* a, long degree_b, double* b,
                        double* result, usz* result_count) {
    double* base;
    double* other;
    long base_degree;
    long other_degree;
    if (degree_a > degree_b) {
        base = a;
        other = b;
        base_degree = degree_a;
        other_degree = degree_b;
    } else {
        base = b;
        other = a;
        base_degree = degree_b;
        other_degree = degree_a;
    }
    for (long index = 0; index <= base_degree; index++) result[index] = base[index];
    for (long index = 0; index <= other_degree; index++)
        result[index] = rounded_add(result[index], other[index]);
    *result_count = (usz)(base_degree + 1);
}

fn void multiply_polynomials(long degree_a, double* a, long degree_b, double* b,
                             double* result, usz* result_count) {
    long degree = degree_a + degree_b;
    for (long index = 0; index <= degree; index++) result[index] = 0.0;
    for (long i = 0; i <= degree_a; i++) {
        for (long j = 0; j <= degree_b; j++) {
            double product = rounded_multiply(a[i], b[j]);
            result[i + j] = rounded_add(result[i + j], product);
        }
    }
    *result_count = (usz)(degree + 1);
}

fn long single_indeterminate_operations(double* values, usz length, double* output,
                                       usz output_capacity)
    @export("single_indeterminate_operations") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < length; index++)
        if (!finite_value(values[index])) return -1L;

    long operation;
    if (!exact_integer_in_range(values[0], OP_ADD, OP_INTEGRAL, &operation)) return -1L;

    double[MAX_COEFFICIENTS] coefficients_a = zeroed;
    double[MAX_COEFFICIENTS] coefficients_b = zeroed;
    long degree_a;
    usz cursor = 1;
    if (!read_polynomial(values, length, &cursor, &degree_a, &coefficients_a[0])) return -1L;

    long degree_b = 0;
    if (operation <= OP_MULTIPLY &&
        !read_polynomial(values, length, &cursor, &degree_b, &coefficients_b[0])) return -1L;

    double parameter = 0.0;
    if (operation == OP_DERIVATIVE) {
        if (cursor != length) return -1L;
    } else if (operation == OP_EVALUATE || operation == OP_INTEGRAL) {
        if (cursor + 1 != length) return -1L;
        parameter = values[cursor];
        double minimum = operation == OP_EVALUATE ? -2.0 : -10.0;
        double maximum = operation == OP_EVALUATE ? 2.0 : 10.0;
        if (parameter < minimum || parameter > maximum) return -1L;
    } else if (cursor != length) {
        return -1L;
    }

    double[MAX_OUTPUT_ELEMENTS] result = zeroed;
    usz result_count = 0;
    if (operation == OP_ADD) {
        add_polynomials(degree_a, &coefficients_a[0], degree_b, &coefficients_b[0],
                        &result[0], &result_count);
    } else if (operation == OP_SUBTRACT) {
        double[MAX_COEFFICIENTS] negated = zeroed;
        for (long index = 0; index <= degree_b; index++) {
            double product = rounded_multiply(coefficients_b[index], -1.0);
            negated[index] = rounded_add(negated[index], product);
        }
        add_polynomials(degree_a, &coefficients_a[0], degree_b, &negated[0],
                        &result[0], &result_count);
    } else if (operation == OP_MULTIPLY) {
        multiply_polynomials(degree_a, &coefficients_a[0], degree_b, &coefficients_b[0],
                             &result[0], &result_count);
    } else if (operation == OP_EVALUATE) {
        double accumulated = 0.0;
        for (long index = 0; index <= degree_a; index++) {
            double power = pow(parameter, (double)index);
            double term = rounded_multiply(coefficients_a[index], power);
            accumulated = rounded_add(accumulated, term);
        }
        result[0] = accumulated;
        result_count = 1;
    } else if (operation == OP_DERIVATIVE) {
        for (long index = 0; index < degree_a; index++)
            result[index] = rounded_multiply(coefficients_a[index + 1], (double)(index + 1));
        result_count = (usz)degree_a;
    } else {
        result[0] = parameter;
        for (long index = 0; index <= degree_a; index++)
            result[index + 1] = rounded_divide(coefficients_a[index], (double)(index + 1));
        result_count = (usz)(degree_a + 2);
    }

    if (result_count > MAX_OUTPUT_ELEMENTS) return -1L;
    for (usz index = 0; index < result_count; index++)
        if (!finite_value(result[index])) return -1L;

    if (output == null || output_capacity < result_count) return -2L;
    for (usz index = 0; index < result_count; index++) output[index] = result[index];
    return (long)result_count;
}
