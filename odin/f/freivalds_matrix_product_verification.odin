package freivalds_matrix_product_verification
import "core:c"

MAX_N :: 8
MAX_INPUT :: 259

@(export)
freivalds_matrix_product_verification :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, rounds64 := input[0], input[1]
    if n64 < 1 || n64 > 8 || rounds64 < 1 || rounds64 > 8 do return -1
    n, rounds := int(n64), int(rounds64)
    matrix_words := n * n
    if length != c.size_t(2 + 3*matrix_words + rounds*n) do return -1
    for word := 2; word < 2 + 3*matrix_words; word += 1 {
        if input[word] < -3 || input[word] > 3 do return -1
    }
    signs_offset := 2 + 3*matrix_words
    for word := signs_offset; word < int(length); word += 1 {
        if input[word] != -1 && input[word] != 1 do return -1
    }

    bx: [MAX_N]i64
    abx: [MAX_N]i64
    cx: [MAX_N]i64
    for round := 0; round < rounds; round += 1 {
        for row := 0; row < n; row += 1 {
            sum := i64(0)
            for col := 0; col < n; col += 1 {
                sum += input[2+matrix_words+row*n+col] * input[signs_offset+round*n+col]
            }
            bx[row] = sum
        }
        for row := 0; row < n; row += 1 {
            left, right := i64(0), i64(0)
            for col := 0; col < n; col += 1 {
                left += input[2+row*n+col] * bx[col]
                right += input[2+2*matrix_words+row*n+col] * input[signs_offset+round*n+col]
            }
            abx[row], cx[row] = left, right
        }
        for row := 0; row < n; row += 1 {
            if abx[row] != cx[row] do return 0
        }
    }
    return 1
}
