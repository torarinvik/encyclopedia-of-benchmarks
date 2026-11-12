from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_STATES = 1 << MAX_N
comptime MAX_OUTPUT_WORDS = 2 + MAX_N
comptime MAX_INPUT_VALUES = 2 + 3 * (MAX_N * (MAX_N - 1) // 2) + 1
comptime MAX_WEIGHT = 1_000_000

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
                value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("general_weighted_matching")
fn general_weighted_matching(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_VALUES):
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > n_value * (n_value - 1) // 2:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 3 * m):
        return -1

    var weights = InlineArray[Int64, MAX_N * MAX_N](fill=0)
    var present = InlineArray[Bool, MAX_N * MAX_N](fill=False)
    var cursor = 2
    for _ in range(m):
        let u_value = input[cursor]
        let v_value = input[cursor + 1]
        let edge_weight = input[cursor + 2]
        cursor += 3
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value or edge_weight < 1 or edge_weight > MAX_WEIGHT:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        let uv = u * MAX_N + v
        let vu = v * MAX_N + u
        if present[uv]:
            return -1
        present[uv] = True
        present[vu] = True
        weights[uv] = edge_weight
        weights[vu] = edge_weight

    var dp = InlineArray[Int64, MAX_STATES](fill=0)
    let state_count = 1 << n
    for mask in range(1, state_count):
        let bit = mask & (-mask)
        var vertex = 0
        while (bit >> vertex) != 1:
            vertex += 1
        let remainder = mask ^ bit
        dp[mask] = dp[remainder]
        for partner in range(vertex + 1, n):
            let partner_bit = 1 << partner
            let edge_index = vertex * MAX_N + partner
            if (remainder & partner_bit) == 0 or not present[edge_index]:
                continue
            let candidate = weights[edge_index] + dp[remainder ^ partner_bit]
            if candidate > dp[mask]:
                dp[mask] = candidate

    var words = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    var pair_count = 0
    var mask = state_count - 1
    while mask != 0:
        let bit = mask & (-mask)
        var vertex = 0
        while (bit >> vertex) != 1:
            vertex += 1
        let remainder = mask ^ bit
        if dp[mask] == dp[remainder]:
            mask = remainder
            continue
        var selected = -1
        for partner in range(vertex + 1, n):
            let partner_bit = 1 << partner
            let edge_index = vertex * MAX_N + partner
            if (remainder & partner_bit) != 0 and present[edge_index] and weights[edge_index] + dp[remainder ^ partner_bit] == dp[mask]:
                selected = partner
                break
        if selected < 0:
            return -1
        words[2 + 2 * pair_count] = vertex
        words[3 + 2 * pair_count] = selected
        pair_count += 1
        mask = remainder ^ (1 << selected)

    words[0] = pair_count
    words[1] = dp[state_count - 1]
    let output_words = 2 + 2 * pair_count
    let output_bytes = 8 * output_words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for word in range(output_words):
        store_i64_le(output, 8 * word, words[word])
    return Int64(output_bytes)
