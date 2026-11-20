from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import pow
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_NONZER = 4
comptime MAX_SUPPORT = 5
comptime MAX_TRIPLETS = 416
comptime MAX_INPUT = 3 + 2 * MAX_N * MAX_NONZER
comptime MAX_VALUE_MICRO: Int64 = 1_000_000
comptime MAX_SHIFT_MICRO: Int64 = 10_000_000
comptime SCALE = 1_000_000.0
comptime RCOND = 0.1

fn npb_cg_put_u64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, bits: UInt64):
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn npb_cg_sparse_outer_product_assembly(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or Int(length) < 3 or Int(length) > MAX_INPUT:
        return -1
    let input_length = Int(length)
    if input[0] < 2 or input[0] > Int64(MAX_N) or input[1] < 1 or input[1] > Int64(MAX_NONZER) or
        input[2] < 0 or input[2] > MAX_SHIFT_MICRO:
        return -1
    let n = Int(input[0])
    let nonzer = Int(input[1])
    if input_length != 3 + 2 * n * nonzer:
        return -1
    var cursor = 3
    for _vector in range(n):
        var seen: UInt32 = 0
        for _entry in range(nonzer):
            let coordinate = input[cursor]
            let value = input[cursor + 1]
            cursor += 2
            if coordinate < 0 or coordinate >= Int64(n) or value == 0 or
                value < -MAX_VALUE_MICRO or value > MAX_VALUE_MICRO:
                return -1
            let bit = UInt32(1) << UInt(coordinate)
            if (seen & bit) != 0:
                return -1
            seen |= bit

    var raw_rows = InlineArray[UInt8, MAX_TRIPLETS]()
    var raw_columns = InlineArray[UInt8, MAX_TRIPLETS]()
    var raw_values = InlineArray[Float64, MAX_TRIPLETS]()
    var raw_count = 0
    cursor = 3
    for vector in range(n):
        var coordinates = InlineArray[UInt8, MAX_SUPPORT]()
        var vector_values = InlineArray[Float64, MAX_SUPPORT]()
        var support_count = nonzer
        var has_anchor = False
        for entry in range(nonzer):
            let coordinate = Int(input[cursor])
            coordinates[entry] = UInt8(coordinate)
            vector_values[entry] = Float64(input[cursor + 1]) / SCALE
            cursor += 2
            if coordinate == vector:
                vector_values[entry] = 0.5
                has_anchor = True
        if not has_anchor:
            coordinates[support_count] = UInt8(vector)
            vector_values[support_count] = 0.5
            support_count += 1
        var weight: Float64 = 1.0
        if vector == n - 1:
            weight = RCOND
        elif vector > 0:
            weight = pow(RCOND, Float64(vector) / Float64(n - 1))
        for column_slot in range(support_count):
            let scaled_column = weight * vector_values[column_slot]
            for row_slot in range(support_count):
                raw_rows[raw_count] = coordinates[row_slot]
                raw_columns[raw_count] = coordinates[column_slot]
                raw_values[raw_count] = vector_values[row_slot] * scaled_column
                raw_count += 1

    let diagonal_addend = RCOND - Float64(input[2]) / SCALE
    for diagonal in range(n):
        raw_rows[raw_count] = UInt8(diagonal)
        raw_columns[raw_count] = UInt8(diagonal)
        raw_values[raw_count] = diagonal_addend
        raw_count += 1

    var column_pointers = InlineArray[Int64, MAX_N + 1]()
    var row_indices = InlineArray[UInt8, MAX_N * MAX_N]()
    var matrix_values = InlineArray[Float64, MAX_N * MAX_N]()
    var nnz = 0
    for column in range(n):
        column_pointers[column] = Int64(nnz)
        for row in range(n):
            var total: Float64 = 0.0
            var touched = False
            for triple in range(raw_count):
                if Int(raw_rows[triple]) == row and Int(raw_columns[triple]) == column:
                    total += raw_values[triple]
                    touched = True
            if touched:
                row_indices[nnz] = UInt8(row)
                matrix_values[nnz] = total
                nnz += 1
    column_pointers[n] = Int64(nnz)

    let required = 8 * (2 + (n + 1) + 2 * nnz)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var offset = 0
    npb_cg_put_u64(output, offset, bitcast[UInt64](Float64(n)))
    offset += 8
    npb_cg_put_u64(output, offset, bitcast[UInt64](Float64(nnz)))
    offset += 8
    for i in range(n + 1):
        npb_cg_put_u64(output, offset, bitcast[UInt64](Float64(column_pointers[i])))
        offset += 8
    for i in range(nnz):
        npb_cg_put_u64(output, offset, bitcast[UInt64](Float64(row_indices[i])))
        offset += 8
    for i in range(nnz):
        npb_cg_put_u64(output, offset, bitcast[UInt64](matrix_values[i]))
        offset += 8
    return Int64(required)
