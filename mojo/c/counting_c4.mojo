from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_VERTICES: Int = 8
const MAX_EDGES: Int = 12
const MAX_INPUT_LENGTH: Int = 26
const MAX_OUTPUT_BYTES: Int = 96

@export("counting_c4")
fn counting_c4(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 2 or n_value > MAX_VERTICES or m_value < 1 or m_value > MAX_EDGES:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m):
        return -1

    var multiplicity = InlineArray[Int64, MAX_VERTICES * MAX_VERTICES](fill=0)
    for edge in range(m):
        let u_value = input[2 + 2 * edge]
        let v_value = input[3 + 2 * edge]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        multiplicity[u * MAX_VERTICES + v] += 1
        multiplicity[v * MAX_VERTICES + u] += 1

    var answers = InlineArray[UInt64, MAX_EDGES](fill=0)
    for edge in range(m):
        let u = Int(input[2 + 2 * edge])
        let v = Int(input[3 + 2 * edge])
        for a in range(n):
            if a == u or a == v:
                continue
            for b in range(n):
                if b == u or b == v or b == a:
                    continue
                answers[edge] += UInt64(
                    multiplicity[u * MAX_VERTICES + a] *
                    multiplicity[a * MAX_VERTICES + b] *
                    multiplicity[b * MAX_VERTICES + v]
                )

    let bytes = 8 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    var staged = InlineArray[UInt8, MAX_OUTPUT_BYTES](fill=0)
    for edge in range(m):
        for byte in range(8):
            staged[8 * edge + byte] = UInt8((answers[edge] >> UInt(8 * byte)) & 255)
    for byte in range(bytes):
        output[byte] = staged[byte]
    return Int64(bytes)
