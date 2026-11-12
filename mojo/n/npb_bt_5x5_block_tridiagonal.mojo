from std.ffi import c_size_t
from std.math import abs
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime BLOCK = 5
comptime MAX_LINE = 4
comptime ROW_WORDS = 80
comptime INVALID_RESULT: Float64 = -1e300


fn solve_block(
    matrix: InlineArray[Float64, 25],
    right: InlineArray[Float64, 30],
    mut answer: InlineArray[Float64, 30],
) -> Bool:
    var work = InlineArray[Float64, 55](fill=0.0)
    for r in range(BLOCK):
        for c in range(BLOCK):
            work[r * 11 + c] = matrix[r * 5 + c]
        for c in range(6):
            work[r * 11 + 5 + c] = right[r * 6 + c]
    for pivot in range(BLOCK):
        var best = pivot
        for r in range(pivot + 1, BLOCK):
            if abs(work[r * 11 + pivot]) > abs(work[best * 11 + pivot]):
                best = r
        if work[best * 11 + pivot] == 0.0:
            return False
        for c in range(11):
            let temporary = work[pivot * 11 + c]
            work[pivot * 11 + c] = work[best * 11 + c]
            work[best * 11 + c] = temporary
        let divisor = work[pivot * 11 + pivot]
        for c in range(pivot, 11):
            work[pivot * 11 + c] /= divisor
        for r in range(BLOCK):
            if r == pivot:
                continue
            let factor = work[r * 11 + pivot]
            for c in range(pivot, 11):
                work[r * 11 + c] -= factor * work[pivot * 11 + c]
    for r in range(BLOCK):
        for c in range(6):
            answer[r * 6 + c] = work[r * 11 + 5 + c]
    return True


@export("npb_bt_5x5_block_tridiagonal")
fn npb_bt_5x5_block_tridiagonal(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(321):
        return INVALID_RESULT
    if values[0] < 2 or values[0] > MAX_LINE:
        return INVALID_RESULT
    let n = Int(values[0])
    if Int(length) != 1 + ROW_WORDS * n:
        return INVALID_RESULT

    var lower = InlineArray[Float64, 100](fill=0.0)
    var diagonal = InlineArray[Float64, 100](fill=0.0)
    var upper = InlineArray[Float64, 100](fill=0.0)
    var rhs = InlineArray[Float64, 20](fill=0.0)
    for row in range(n):
        var cursor = 1 + ROW_WORDS * row
        for which in range(3):
            for r in range(BLOCK):
                for c in range(BLOCK):
                    let value = values[cursor]
                    cursor += 1
                    if which == 1:
                        if r == c:
                            if value < 40 or value > 64:
                                return INVALID_RESULT
                        elif value < -2 or value > 2:
                            return INVALID_RESULT
                        diagonal[row * 25 + r * 5 + c] = Float64(value)
                    else:
                        if value < -2 or value > 2:
                            return INVALID_RESULT
                        if which == 0:
                            lower[row * 25 + r * 5 + c] = Float64(value)
                        else:
                            upper[row * 25 + r * 5 + c] = Float64(value)
        for r in range(BLOCK):
            let value = values[cursor]
            cursor += 1
            if value < -1000 or value > 1000:
                return INVALID_RESULT
            rhs[row * 5 + r] = Float64(value)
        for r in range(BLOCK):
            for c in range(BLOCK):
                if row == 0 and lower[row * 25 + r * 5 + c] != 0.0:
                    return INVALID_RESULT
                if row + 1 == n and upper[row * 25 + r * 5 + c] != 0.0:
                    return INVALID_RESULT
        for r in range(BLOCK):
            var off_diagonal = Float64(0.0)
            for c in range(BLOCK):
                if r != c:
                    off_diagonal += abs(diagonal[row * 25 + r * 5 + c])
                off_diagonal += abs(lower[row * 25 + r * 5 + c]) + abs(upper[row * 25 + r * 5 + c])
            if diagonal[row * 25 + r * 5 + r] <= off_diagonal:
                return INVALID_RESULT

    var modified_upper = InlineArray[Float64, 100](fill=0.0)
    var modified_rhs = InlineArray[Float64, 20](fill=0.0)
    for row in range(n):
        var schur = InlineArray[Float64, 25](fill=0.0)
        var reduced = InlineArray[Float64, 5](fill=0.0)
        var right = InlineArray[Float64, 30](fill=0.0)
        var solved = InlineArray[Float64, 30](fill=0.0)
        for r in range(BLOCK):
            reduced[r] = rhs[row * 5 + r]
            for c in range(BLOCK):
                var value = diagonal[row * 25 + r * 5 + c]
                if row > 0:
                    for k in range(BLOCK):
                        value -= lower[row * 25 + r * 5 + k] * modified_upper[(row - 1) * 25 + k * 5 + c]
                schur[r * 5 + c] = value
            if row > 0:
                for k in range(BLOCK):
                    reduced[r] -= lower[row * 25 + r * 5 + k] * modified_rhs[(row - 1) * 5 + k]
            for c in range(BLOCK):
                right[r * 6 + c] = upper[row * 25 + r * 5 + c]
            right[r * 6 + 5] = reduced[r]
        if not solve_block(schur, right, solved):
            return INVALID_RESULT
        for r in range(BLOCK):
            modified_rhs[row * 5 + r] = solved[r * 6 + 5]
            for c in range(BLOCK):
                modified_upper[row * 25 + r * 5 + c] = solved[r * 6 + c]

    var solution = InlineArray[Float64, 20](fill=0.0)
    for r in range(BLOCK):
        solution[(n - 1) * 5 + r] = modified_rhs[(n - 1) * 5 + r]
    for offset in range(n - 1):
        let row = n - 2 - offset
        for r in range(BLOCK):
            solution[row * 5 + r] = modified_rhs[row * 5 + r]
            for c in range(BLOCK):
                solution[row * 5 + r] -= modified_upper[row * 25 + r * 5 + c] * solution[(row + 1) * 5 + c]
    var checksum = Float64(0.0)
    for q in range(n * BLOCK):
        checksum += Float64(q + 1) * solution[q]
    return checksum
