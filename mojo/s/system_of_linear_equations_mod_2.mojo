from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 32
alias MAX_M = 32
alias MAX_INPUT_VALUES = 2 + MAX_N * MAX_M + MAX_N

def system_of_linear_equations_mod_2_store(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: usize, value: UInt64
) -> None:
    for byte in range(8):
        output[offset + byte] = UInt8((value >> UInt(8 * byte)) & 255)

@export("system_of_linear_equations_mod_2")
fn system_of_linear_equations_mod_2(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 1 or m_value > MAX_M:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + n * m + n):
        return -1

    var rows = InlineArray[UInt64, MAX_N]()
    var rhs = InlineArray[UInt8, MAX_N]()
    for row in range(n):
        for column in range(m):
            let bit = input[2 + row * m + column]
            if bit != 0 and bit != 1:
                return -1
            rows[row] = rows[row] | (UInt64(bit) << UInt(column))
        let bit = input[2 + n * m + row]
        if bit != 0 and bit != 1:
            return -1
        rhs[row] = UInt8(bit)

    var pivot_columns = InlineArray[Int, MAX_N]()
    var pivot_row = 0
    for column in range(m):
        var pivot = pivot_row
        while pivot < n and ((rows[pivot] >> UInt(column)) & 1) == 0:
            pivot += 1
        if pivot == n:
            continue
        let row_temporary = rows[pivot_row]
        rows[pivot_row] = rows[pivot]
        rows[pivot] = row_temporary
        let rhs_temporary = rhs[pivot_row]
        rhs[pivot_row] = rhs[pivot]
        rhs[pivot] = rhs_temporary
        for row in range(n):
            if row != pivot_row and ((rows[row] >> UInt(column)) & 1) != 0:
                rows[row] = rows[row] ^ rows[pivot_row]
                rhs[row] = rhs[row] ^ rhs[pivot_row]
        pivot_columns[pivot_row] = column
        pivot_row += 1

    for row in range(pivot_row, n):
        if rows[row] == 0 and rhs[row] != 0:
            if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
                return -2
            system_of_linear_equations_mod_2_store(output, 0, UInt64.max)
            return 8

    var is_pivot = InlineArray[Bool, MAX_M]()
    for row in range(pivot_row):
        is_pivot[pivot_columns[row]] = True
    let nullity = m - pivot_row
    let output_bytes = 8 * (nullity + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var particular: UInt64 = 0
    for row in range(pivot_row):
        if rhs[row] != 0:
            particular = particular | (UInt64(1) << UInt(pivot_columns[row]))
    system_of_linear_equations_mod_2_store(output, 0, UInt64(nullity))
    system_of_linear_equations_mod_2_store(output, 8, particular)
    var basis_index = 0
    for free_column in range(m):
        if is_pivot[free_column]:
            continue
        var basis = UInt64(1) << UInt(free_column)
        for row in range(pivot_row):
            if ((rows[row] >> UInt(free_column)) & 1) != 0:
                basis = basis | (UInt64(1) << UInt(pivot_columns[row]))
        system_of_linear_equations_mod_2_store(output, 16 + 8 * basis_index, basis)
        basis_index += 1
    return Int64(output_bytes)
