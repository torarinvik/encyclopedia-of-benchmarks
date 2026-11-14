package wavelet_matrix

import "core:c"

Matrix :: struct { prefix: [11][65]int, zeros: [11]int }

less :: proc "contextless" (matrix: ^Matrix, first, last, key: int) -> int {
    left, right, result := first, last, 0
    for level := 0; level < 11; level += 1 {
        zl, zr := matrix.prefix[level][left], matrix.prefix[level][right]
        if key & (1 << u64(10-level)) != 0 {
            result += zr-zl
            left = matrix.zeros[level]+left-zl
            right = matrix.zeros[level]+right-zr
        } else { left = zl; right = zr }
    }
    return result
}

quantile :: proc "contextless" (matrix: ^Matrix, first, last, rank: int) -> int {
    left, right, k, key := first, last, rank, 0
    for level := 0; level < 11; level += 1 {
        zl, zr := matrix.prefix[level][left], matrix.prefix[level][right]
        if k < zr-zl { left = zl; right = zr }
        else {
            k -= zr-zl
            key |= 1 << u64(10-level)
            left = matrix.zeros[level]+left-zl
            right = matrix.zeros[level]+right-zr
        }
    }
    return key-1000
}

@(export)
wavelet_matrix :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 706 || input[0] < 1 || input[0] > 64 { return -1 }
    n := int(input[0])
    if int(length) < n+2 { return -1 }
    for i := 0; i < n; i += 1 { if input[1+i] < -1000 || input[1+i] > 1000 { return -1 } }
    q := input[n+1]
    if q < 0 || q > 128 || int(length) != n+2+5*int(q) { return -1 }
    matrix: Matrix
    current, scratch: [64]int
    for i := 0; i < n; i += 1 { current[i] = int(input[1+i])+1000 }
    for level := 0; level < 11; level += 1 {
        bit := u64(10-level)
        for i := 0; i < n; i += 1 {
            matrix.prefix[level][i+1] = matrix.prefix[level][i]
            if current[i] & (1 << bit) == 0 { matrix.prefix[level][i+1] += 1 }
        }
        z, o := 0, matrix.prefix[level][n]
        matrix.zeros[level] = o
        for i := 0; i < n; i += 1 {
            if current[i] & (1 << bit) == 0 { scratch[z] = current[i]; z += 1 }
            else { scratch[o] = current[i]; o += 1 }
        }
        for i := 0; i < n; i += 1 { current[i] = scratch[i] }
    }
    total: i64 = 0
    for j := 0; j < int(q); j += 1 {
        at := n+2+5*j
        op, a, b, c, d := input[at], input[at+1], input[at+2], input[at+3], input[at+4]
        answer := 0
        if op == 0 {
            if a < -1000 || a > 1000 || b < -1 || b >= i64(n) { return -1 }
            answer = less(&matrix, 0, int(b)+1, int(a)+1001)-less(&matrix, 0, int(b)+1, int(a)+1000)
        } else if op == 1 {
            if a < 0 || a > b || b >= i64(n) || c < 0 || c > b-a { return -1 }
            answer = quantile(&matrix, int(a), int(b)+1, int(c))
        } else if op == 2 {
            if a < 0 || a > b || b >= i64(n) || c < -1000 || c > d || d > 1000 { return -1 }
            answer = less(&matrix, int(a), int(b)+1, int(d)+1001)-less(&matrix, int(a), int(b)+1, int(c)+1000)
        } else { return -1 }
        total += i64(j+1) * i64(answer+1000001)
    }
    return total
}
