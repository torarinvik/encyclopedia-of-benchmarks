# Clean-room bounded linear-tetrahedron force kernel.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime TFK_MAX_ELEMENTS = 32
comptime TFK_MAX_VALID_INPUT = 387
comptime TFK_MAX_PARSEABLE_INPUT = 388
comptime TFK_MAX_OUTPUT_BYTES = 3072

fn tfk_store_i64(inout staged: InlineArray[UInt8, TFK_MAX_OUTPUT_BYTES],
                 offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        staged[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("tetrahedral_element_force_kernel")
fn tetrahedral_element_force_kernel(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or
       length < c_size_t(3) or length > c_size_t(TFK_MAX_PARSEABLE_INPUT):
        return -1
    let element_count_value = input[0]
    let lame_lambda = input[1]
    let lame_mu = input[2]
    if element_count_value < 1 or element_count_value > TFK_MAX_ELEMENTS:
        return -1
    if length != c_size_t(3 + 12 * Int(element_count_value)):
        return -1
    if lame_lambda < 0 or lame_lambda > 16 or lame_mu < 0 or lame_mu > 16:
        return -1
    let element_count = Int(element_count_value)
    for index in range(3, Int(length)):
        if input[index] < -4 or input[index] > 4:
            return -1

    let required = 96 * element_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var staged = InlineArray[UInt8, TFK_MAX_OUTPUT_BYTES](fill=UInt8(0))
    for element in range(element_count):
        let input_base = 3 + 12 * element
        var deformation = InlineArray[Int64, 9](fill=Int64(0))
        for row in range(3):
            for column in range(3):
                deformation[3 * row + column] =
                    input[input_base + 3 * (column + 1) + row] - input[input_base + row]
        let trace_delta = deformation[0] + deformation[4] + deformation[8] - Int64(3)

        var stress = InlineArray[Int64, 9](fill=Int64(0))
        for row in range(3):
            for column in range(3):
                let diagonal: Int64 = Int64(1) if row == column else Int64(0)
                stress[3 * row + column] = lame_lambda * trace_delta * diagonal + lame_mu * (
                    deformation[3 * row + column] + deformation[3 * column + row]
                    - Int64(2) * diagonal)

        let output_base = 12 * element
        for row in range(3):
            var row_sum = Int64(0)
            for column in range(3):
                row_sum += stress[3 * row + column]
            tfk_store_i64(staged, 8 * (output_base + row), row_sum)
        for vertex in range(3):
            for row in range(3):
                tfk_store_i64(staged, 8 * (output_base + 3 * (vertex + 1) + row),
                              -stress[3 * row + vertex])

    for index in range(required):
        output[index] = staged[index]
    Int64(required)
