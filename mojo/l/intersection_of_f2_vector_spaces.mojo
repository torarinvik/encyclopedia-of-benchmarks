from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_CASES = 4
alias MAX_VECTORS = 8
alias MAX_BITS = 30
alias MAX_INPUT_VALUES = 1 + MAX_CASES * (2 + 2 * MAX_VECTORS) + 1
alias MAX_OUTPUT_WORDS = MAX_CASES * (1 + MAX_VECTORS)
alias MAX_VECTOR = UInt32(0x3fffffff)

fn insert_independent(mut basis: InlineArray[UInt32, MAX_BITS], value: UInt32) -> Bool:
    var row = value
    for bit in range(MAX_BITS - 1, -1, -1):
        let mask = UInt32(1) << bit
        if (row & mask) == 0:
            continue
        if basis[bit] != 0:
            row = row ^ basis[bit]
        else:
            basis[bit] = row
            return True
    return False

fn intersection_basis(left: InlineArray[UInt32, MAX_VECTORS], n: Int,
    right: InlineArray[UInt32, MAX_VECTORS], m: Int,
    mut output: InlineArray[UInt32, MAX_VECTORS]) -> Int:
    var right_basis = InlineArray[UInt32, MAX_BITS]()
    var right_coeff = InlineArray[UInt32, MAX_BITS]()
    for index in range(m):
        var row = right[index]
        var coefficients = UInt32(1) << index
        for bit in range(MAX_BITS - 1, -1, -1):
            let mask = UInt32(1) << bit
            if (row & mask) == 0:
                continue
            if right_basis[bit] != 0:
                row = row ^ right_basis[bit]
                coefficients = coefficients ^ right_coeff[bit]
            else:
                right_basis[bit] = row
                right_coeff[bit] = coefficients
                break

    var quotient_basis = InlineArray[UInt32, MAX_BITS]()
    var quotient_left_coeff = InlineArray[UInt32, MAX_BITS]()
    var quotient_right_coeff = InlineArray[UInt32, MAX_BITS]()
    var intersection = InlineArray[UInt32, MAX_VECTORS]()
    var intersection_count = 0
    for index in range(n):
        var row = left[index]
        var right_mask: UInt32 = 0
        for bit in range(MAX_BITS - 1, -1, -1):
            let mask = UInt32(1) << bit
            if (row & mask) != 0 and right_basis[bit] != 0:
                row = row ^ right_basis[bit]
                right_mask = right_mask ^ right_coeff[bit]
        var left_mask = UInt32(1) << index
        for bit in range(MAX_BITS - 1, -1, -1):
            let mask = UInt32(1) << bit
            if (row & mask) == 0:
                continue
            if quotient_basis[bit] != 0:
                row = row ^ quotient_basis[bit]
                left_mask = left_mask ^ quotient_left_coeff[bit]
                right_mask = right_mask ^ quotient_right_coeff[bit]
            else:
                quotient_basis[bit] = row
                quotient_left_coeff[bit] = left_mask
                quotient_right_coeff[bit] = right_mask
                break
        if row == 0:
            var common: UInt32 = 0
            for source in range(n):
                if ((left_mask >> source) & 1) != 0:
                    common = common ^ left[source]
            intersection[intersection_count] = common
            intersection_count += 1

    var rref = InlineArray[UInt32, MAX_BITS]()
    for index in range(intersection_count):
        var row = intersection[index]
        for bit in range(MAX_BITS - 1, -1, -1):
            let mask = UInt32(1) << bit
            if (row & mask) == 0:
                continue
            if rref[bit] != 0:
                row = row ^ rref[bit]
            else:
                rref[bit] = row
                for pivot in range(MAX_BITS):
                    if pivot != bit and ((rref[pivot] >> bit) & 1) != 0:
                        rref[pivot] = rref[pivot] ^ row
                break
    var output_count = 0
    for bit in range(MAX_BITS - 1, -1, -1):
        if rref[bit] != 0:
            output[output_count] = rref[bit]
            output_count += 1
    return output_count

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("intersection_of_f2_vector_spaces")
fn intersection_of_f2_vector_spaces(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_VALUES:
        return -1
    let case_count_value = input[0]
    if case_count_value < 1 or case_count_value > MAX_CASES:
        return -1
    let case_count = Int(case_count_value)
    var staged = InlineArray[Int64, MAX_OUTPUT_WORDS]()
    var used = 0
    var cursor = 1
    for _ in range(case_count):
        if cursor >= Int(length):
            return -1
        let n_value = input[cursor]
        cursor += 1
        if n_value < 0 or n_value > MAX_VECTORS:
            return -1
        let n = Int(n_value)
        if cursor + n > Int(length):
            return -1
        var left = InlineArray[UInt32, MAX_VECTORS]()
        var left_check = InlineArray[UInt32, MAX_BITS]()
        for index in range(n):
            let value = input[cursor]
            cursor += 1
            if value < 0 or value > Int64(MAX_VECTOR):
                return -1
            let vector = UInt32(value)
            if not insert_independent(mut left_check, vector):
                return -1
            left[index] = vector
        if cursor >= Int(length):
            return -1
        let m_value = input[cursor]
        cursor += 1
        if m_value < 0 or m_value > MAX_VECTORS:
            return -1
        let m = Int(m_value)
        if cursor + m > Int(length):
            return -1
        var right = InlineArray[UInt32, MAX_VECTORS]()
        var right_check = InlineArray[UInt32, MAX_BITS]()
        for index in range(m):
            let value = input[cursor]
            cursor += 1
            if value < 0 or value > Int64(MAX_VECTOR):
                return -1
            let vector = UInt32(value)
            if not insert_independent(mut right_check, vector):
                return -1
            right[index] = vector
        var basis = InlineArray[UInt32, MAX_VECTORS]()
        let dimension = intersection_basis(left, n, right, m, mut basis)
        staged[used] = Int64(dimension)
        used += 1
        for index in range(dimension):
            staged[used] = Int64(basis[index])
            used += 1
    if cursor != Int(length):
        return -1
    let required = 8 * used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(required):
        return -2
    for index in range(used):
        store_i64_le(output, 8 * index, staged[index])
    return Int64(required)
