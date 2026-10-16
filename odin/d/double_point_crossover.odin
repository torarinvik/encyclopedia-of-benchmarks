package double_point_crossover

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte in 0 ..< 8 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) }
}

@(export, link_name="double_point_crossover")
double_point_crossover :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
    if input == nil || length < 7 || length > 131 do return -1
    n, j1, j2 := input[0], input[1], input[2]
    if n < 2 || n > 64 || length != uint(3 + 2 * n) || j1 < 1 || j1 >= j2 || j2 > n do return -1
    for i: i64 = 0; i < 2 * n; i += 1 { if input[3 + i] < -2147483648 || input[3 + i] > 2147483647 do return -1 }
    count := int(n)
    bytes := 16 * count
    if output == nil || capacity < uint(bytes) do return -2
    for i := 0; i < count; i += 1 {
        child1, child2 := input[3 + i], input[3 + count + i]
        if i >= int(j1) && i < int(j2) do child1, child2 = child2, child1
        put_i64_le(output, i * 8, child1)
        put_i64_le(output, (count + i) * 8, child2)
    }
    return i64(bytes)
}

main :: proc() {}
