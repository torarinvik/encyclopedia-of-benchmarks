// Independent hook-length count; see package README.
package hook_length_tableaux
import "core:c"
PRIME :: i64(998244353)

@(export)
hook_length_tableaux :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length == 0 do return -1
    if input[0] < 0 || input[0] > 65536 do return -1
    rows := int(input[0])
    if length != c.size_t(rows + 1) do return -1
    total := i64(0); previous := i64(1000000)
    for i := 1; i <= rows; i += 1 {
        width := input[i]
        if width < 1 || width > previous do return -1
        total += width; if total > 1000000 do return -1
        previous = width
    }
    hooks := i64(1); height := rows
    if rows > 0 {
        for col := i64(0); col < input[1]; col += 1 {
            for height > 0 && input[height] <= col { height -= 1 }
            for row := 0; row < height; row += 1 {
                hooks = hooks * (input[row + 1] - col + i64(height - row - 1)) % PRIME
            }
        }
    }
    factorial := i64(1)
    for i := i64(2); i <= total; i += 1 { factorial = factorial * i % PRIME }
    inverse := i64(1); exponent := PRIME - 2
    for exponent > 0 {
        if exponent & 1 != 0 { inverse = inverse * hooks % PRIME }
        hooks = hooks * hooks % PRIME; exponent >>= 1
    }
    return factorial * inverse % PRIME
}
