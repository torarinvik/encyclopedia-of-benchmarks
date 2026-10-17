package shortest_common_supersequence

import "core:c"

@(export, link_name="shortest_common_supersequence")
shortest_common_supersequence :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 130 do return -1
    m_value := input[0]
    n_value := input[1]
    if m_value < 0 || m_value > 64 || n_value < 0 || n_value > 64 do return -1
    m := int(m_value)
    n := int(n_value)
    if length != c.size_t(2 + m + n) do return -1
    for index := 0; index < m + n; index += 1 {
        if input[2 + index] < 32 || input[2 + index] > 126 do return -1
    }

    lcs: [65 * 65]i64 = {}
    for i := 1; i <= m; i += 1 {
        for j := 1; j <= n; j += 1 {
            cell := i * 65 + j
            if input[1 + i] == input[1 + m + j] {
                lcs[cell] = lcs[(i - 1) * 65 + j - 1] + 1
            } else {
                above := lcs[(i - 1) * 65 + j]
                left := lcs[i * 65 + j - 1]
                lcs[cell] = max(above, left)
            }
        }
    }

    reversed: [128]u8
    used := 0
    i := m
    j := n
    for i > 0 && j > 0 {
        if input[1 + i] == input[1 + m + j] {
            reversed[used] = u8(input[1 + i])
            used += 1
            i -= 1
            j -= 1
        } else if lcs[(i - 1) * 65 + j] > lcs[i * 65 + j - 1] {
            reversed[used] = u8(input[1 + i])
            used += 1
            i -= 1
        } else {
            // The pinned implementations choose Y when the LCS values tie.
            reversed[used] = u8(input[1 + m + j])
            used += 1
            j -= 1
        }
    }
    for i > 0 {
        reversed[used] = u8(input[1 + i])
        used += 1
        i -= 1
    }
    for j > 0 {
        reversed[used] = u8(input[1 + m + j])
        used += 1
        j -= 1
    }

    if output == nil || capacity < c.size_t(used) do return -2
    for index := 0; index < used; index += 1 {
        output[index] = reversed[used - 1 - index]
    }
    return i64(used)
}
