const FIELD: i32 = 7;
const MAX_N: usize = 7;
const MAX_VARIABLES: usize = 8;
const MAX_POLYNOMIAL: usize = 8;
const MAX_INPUT_LENGTH: usize = 11;

fn normalize(value: i32) i32 {
    return @mod(value, FIELD);
}

fn trimPolynomial(polynomial: *const [MAX_POLYNOMIAL]i32, length: *usize) void {
    while (length.* > 1 and polynomial[length.* - 1] == 0) length.* -= 1;
}

fn solveHomogeneous(
    matrix: *[MAX_N][MAX_VARIABLES]i32,
    row_count: usize,
    variable_count: usize,
    solution: *[MAX_VARIABLES]i32,
) bool {
    const inverse = [7]i32{ 0, 1, 4, 5, 2, 3, 6 };
    var pivot_columns: [MAX_VARIABLES]usize = @splat(0);
    var pivot_count: usize = 0;
    var pivot_row: usize = 0;
    for (0..variable_count) |column| {
        var found: ?usize = null;
        for (pivot_row..row_count) |row| {
            if (matrix[row][column] != 0) {
                found = row;
                break;
            }
        }
        if (found) |found_row| {
            const temporary = matrix[pivot_row];
            matrix[pivot_row] = matrix[found_row];
            matrix[found_row] = temporary;
        } else continue;

        const scale = inverse[@intCast(matrix[pivot_row][column])];
        for (0..variable_count) |c| {
            matrix[pivot_row][c] = normalize(matrix[pivot_row][c] * scale);
        }
        for (0..row_count) |row| {
            if (row == pivot_row) continue;
            const factor = matrix[row][column];
            if (factor == 0) continue;
            for (0..variable_count) |c| {
                matrix[row][c] = normalize(matrix[row][c] - factor * matrix[pivot_row][c]);
            }
        }
        pivot_columns[pivot_count] = column;
        pivot_count += 1;
        pivot_row += 1;
        if (pivot_row == row_count) break;
    }

    var free_column: ?usize = null;
    for (0..variable_count) |column| {
        var is_pivot = false;
        for (0..pivot_count) |index| {
            if (pivot_columns[index] == column) {
                is_pivot = true;
                break;
            }
        }
        if (!is_pivot) {
            free_column = column;
            break;
        }
    }
    if (free_column) |free| {
        solution.* = @splat(0);
        solution[free] = 1;
        for (0..pivot_count) |row| {
            solution[pivot_columns[row]] = normalize(-matrix[row][free]);
        }
        return true;
    }
    return false;
}

fn dividePolynomials(
    numerator: *const [MAX_POLYNOMIAL]i32,
    denominator: *const [MAX_POLYNOMIAL]i32,
    numerator_length: usize,
    denominator_length: usize,
    quotient: *[MAX_POLYNOMIAL]i32,
    quotient_length: *usize,
) bool {
    const inverse = [7]i32{ 0, 1, 4, 5, 2, 3, 6 };
    var remainder = numerator.*;
    var divisor = denominator.*;
    var remainder_length = numerator_length;
    var divisor_length = denominator_length;
    trimPolynomial(&remainder, &remainder_length);
    trimPolynomial(&divisor, &divisor_length);
    if (divisor_length == 1 and divisor[0] == 0) return false;

    quotient.* = @splat(0);
    quotient_length.* = if (remainder_length >= divisor_length)
        remainder_length - divisor_length + 1
    else
        1;
    const inverse_lead = inverse[@intCast(divisor[divisor_length - 1])];
    while (!(remainder_length == 1 and remainder[0] == 0) and remainder_length >= divisor_length) {
        const shift = remainder_length - divisor_length;
        const factor = normalize(remainder[remainder_length - 1] * inverse_lead);
        quotient[shift] = factor;
        for (0..divisor_length) |index| {
            remainder[shift + index] = normalize(remainder[shift + index] - factor * divisor[index]);
        }
        trimPolynomial(&remainder, &remainder_length);
    }
    if (remainder_length != 1 or remainder[0] != 0) return false;
    trimPolynomial(quotient, quotient_length);
    return true;
}

fn decode(n: usize, k: usize, error_limit: usize, received: *const [MAX_N]i32) i64 {
    const q_count = k + error_limit;
    const e_count = error_limit + 1;
    const variable_count = q_count + e_count;
    var matrix: [MAX_N][MAX_VARIABLES]i32 = @splat(@splat(0));
    for (0..n) |row| {
        const x: i32 = @intCast(row);
        var power: i32 = 1;
        for (0..q_count) |degree| {
            matrix[row][degree] = power;
            power = @rem(power * x, FIELD);
        }
        power = 1;
        for (0..e_count) |degree| {
            matrix[row][q_count + degree] = normalize(-received[row] * power);
            power = @rem(power * x, FIELD);
        }
    }

    var solution: [MAX_VARIABLES]i32 = @splat(0);
    if (!solveHomogeneous(&matrix, n, variable_count, &solution)) return 0;
    var numerator: [MAX_POLYNOMIAL]i32 = @splat(0);
    var locator: [MAX_POLYNOMIAL]i32 = @splat(0);
    for (0..q_count) |degree| numerator[degree] = solution[degree];
    for (0..e_count) |degree| locator[degree] = solution[q_count + degree];
    var numerator_length = q_count;
    var locator_length = e_count;
    trimPolynomial(&numerator, &numerator_length);
    trimPolynomial(&locator, &locator_length);

    var coefficients: [MAX_POLYNOMIAL]i32 = @splat(0);
    var coefficient_length: usize = 0;
    if (!dividePolynomials(&numerator, &locator, numerator_length, locator_length,
        &coefficients, &coefficient_length) or coefficient_length > k) return 0;

    var mismatches: usize = 0;
    for (0..n) |x_index| {
        const x: i32 = @intCast(x_index);
        var value: i32 = 0;
        var degree = k;
        while (degree > 0) {
            degree -= 1;
            const coefficient = if (degree < coefficient_length) coefficients[degree] else 0;
            value = @rem(value * x + coefficient, FIELD);
        }
        if (value != received[x_index]) mismatches += 1;
    }
    if (mismatches > error_limit) return 0;

    var encoded: i64 = 1;
    var place: i64 = 1;
    for (0..k) |degree| {
        if (degree < coefficient_length) encoded += @as(i64, @intCast(coefficients[degree])) * place;
        place *= FIELD;
    }
    return encoded;
}

export fn berlekamp_welch_rs_decode(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    const n_value = input[0];
    const k_value = input[1];
    const error_value = input[2];
    if (n_value < 2 or n_value > 7 or k_value < 1 or k_value > 3
        or k_value > n_value or error_value < 0 or error_value > 2) return -1;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    const error_limit: usize = @intCast(error_value);
    if (2 * error_limit > n - k or length != 3 + n) return -1;

    var received: [MAX_N]i32 = @splat(0);
    for (0..n) |index| {
        const symbol = input[3 + index];
        if (symbol < 0 or symbol >= FIELD) return -1;
        received[index] = @intCast(symbol);
    }
    return decode(n, k, error_limit, &received);
}
