from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias BW_MAX_N = 7
alias BW_MAX_K = 3
alias BW_MAX_T = 2
alias BW_MAX_VARS = 8
alias BW_MAX_POLY = 5
alias BW_MAX_INPUT_LENGTH = 11

fn bw_mod7(value: Int64) -> Int64:
    let remainder = value % 7
    return remainder + 7 if remainder < 0 else remainder

fn bw_inverse7(value: Int64) -> Int64:
    if value == 1: return 1
    if value == 2: return 4
    if value == 3: return 5
    if value == 4: return 2
    if value == 5: return 3
    if value == 6: return 6
    return 0

fn bw_decode(n: Int, k: Int, errors: Int,
    received: InlineArray[Int64, BW_MAX_N]) -> Int64:
    let q_count = k + errors
    let e_count = errors + 1
    let variable_count = q_count + e_count
    var matrix = InlineArray[Int64, BW_MAX_N * BW_MAX_VARS]()

    for row in range(n):
        var powers = InlineArray[Int64, BW_MAX_POLY]()
        powers[0] = 1
        for degree in range(1, BW_MAX_POLY):
            powers[degree] = powers[degree - 1] * Int64(row) % 7
        for degree in range(q_count):
            matrix[row * BW_MAX_VARS + degree] = powers[degree]
        for degree in range(e_count):
            matrix[row * BW_MAX_VARS + q_count + degree] = bw_mod7(
                -received[row] * powers[degree])

    var pivot_columns = InlineArray[Int, BW_MAX_VARS]()
    var is_pivot = InlineArray[Bool, BW_MAX_VARS]()
    var pivot_row = 0
    for column in range(variable_count):
        if pivot_row >= n: break
        var found = pivot_row
        while found < n and matrix[found * BW_MAX_VARS + column] == 0:
            found += 1
        if found == n: continue
        for c in range(variable_count):
            let temporary = matrix[pivot_row * BW_MAX_VARS + c]
            matrix[pivot_row * BW_MAX_VARS + c] = matrix[found * BW_MAX_VARS + c]
            matrix[found * BW_MAX_VARS + c] = temporary
        let inverse = bw_inverse7(matrix[pivot_row * BW_MAX_VARS + column])
        for c in range(variable_count):
            matrix[pivot_row * BW_MAX_VARS + c] =
                matrix[pivot_row * BW_MAX_VARS + c] * inverse % 7
        for row in range(n):
            if row == pivot_row: continue
            let factor = matrix[row * BW_MAX_VARS + column]
            if factor == 0: continue
            for c in range(variable_count):
                matrix[row * BW_MAX_VARS + c] = bw_mod7(
                    matrix[row * BW_MAX_VARS + c]
                    - factor * matrix[pivot_row * BW_MAX_VARS + c])
        pivot_columns[pivot_row] = column
        is_pivot[column] = True
        pivot_row += 1

    var free_column = variable_count
    for column in range(variable_count):
        if not is_pivot[column]:
            free_column = column
            break
    if free_column == variable_count: return 0
    var solution = InlineArray[Int64, BW_MAX_VARS]()
    solution[free_column] = 1
    for row in range(pivot_row):
        solution[pivot_columns[row]] = bw_mod7(-matrix[row * BW_MAX_VARS + free_column])

    var numerator = InlineArray[Int64, BW_MAX_POLY]()
    var locator = InlineArray[Int64, BW_MAX_POLY]()
    for degree in range(q_count): numerator[degree] = solution[degree]
    var locator_zero = True
    for degree in range(e_count):
        locator[degree] = solution[q_count + degree]
        if locator[degree] != 0: locator_zero = False
    if locator_zero: return 0
    var locator_degree = e_count - 1
    while locator_degree > 0 and locator[locator_degree] == 0:
        locator_degree -= 1

    var remainder = InlineArray[Int64, BW_MAX_POLY]()
    for degree in range(q_count): remainder[degree] = numerator[degree]
    var remainder_degree = q_count - 1
    while remainder_degree > 0 and remainder[remainder_degree] == 0:
        remainder_degree -= 1
    var numerator_zero = True
    for degree in range(q_count):
        if remainder[degree] != 0: numerator_zero = False

    var quotient = InlineArray[Int64, BW_MAX_POLY]()
    var quotient_count = 1
    if not numerator_zero and remainder_degree >= locator_degree:
        quotient_count = remainder_degree - locator_degree + 1
    let inverse_lead = bw_inverse7(locator[locator_degree])
    while not numerator_zero and remainder_degree >= locator_degree:
        let shift = remainder_degree - locator_degree
        let factor = remainder[remainder_degree] * inverse_lead % 7
        quotient[shift] = factor
        for degree in range(locator_degree + 1):
            remainder[shift + degree] = bw_mod7(
                remainder[shift + degree] - factor * locator[degree])
        while remainder_degree > 0 and remainder[remainder_degree] == 0:
            remainder_degree -= 1
        numerator_zero = True
        for degree in range(q_count):
            if remainder[degree] != 0: numerator_zero = False
    for degree in range(q_count):
        if remainder[degree] != 0: return 0
    if quotient_count > k: return 0

    var coefficients = InlineArray[Int64, BW_MAX_K]()
    for degree in range(quotient_count): coefficients[degree] = quotient[degree]
    var mismatches = 0
    for x in range(n):
        var value: Int64 = 0
        for degree in range(k, 0, -1):
            value = (value * Int64(x) + coefficients[degree - 1]) % 7
        if value != received[x]: mismatches += 1
    if mismatches > errors: return 0

    var result: Int64 = 1
    var place: Int64 = 1
    for degree in range(k):
        result += coefficients[degree] * place
        place *= 7
    return result

@export("berlekamp_welch_rs_decode")
fn berlekamp_welch_rs_decode(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > BW_MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    let k_value = input[1]
    let t_value = input[2]
    if n_value < 2 or n_value > BW_MAX_N or k_value < 1 or k_value > BW_MAX_K or
        k_value > n_value or t_value < 0 or t_value > BW_MAX_T or
        2 * t_value > n_value - k_value:
        return -1
    let n = Int(n_value)
    let k = Int(k_value)
    let errors = Int(t_value)
    if length != c_size_t(3 + n): return -1
    var received = InlineArray[Int64, BW_MAX_N]()
    for index in range(n):
        let symbol = input[3 + index]
        if symbol < 0 or symbol >= 7: return -1
        received[index] = symbol
    return bw_decode(n, k, errors, received)
