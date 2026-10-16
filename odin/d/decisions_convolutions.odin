package decisions_convolutions
import "core:c"

Max_Decisions :: 64
Max_Criteria :: 16
Max_Value :: 100000

@(export)
decisions_convolutions :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 do return -1
    method, n_arg, m_arg := input[0], input[1], input[2]
    if (method != 0 && method != 1) || n_arg < 1 || n_arg > Max_Decisions || m_arg < 1 || m_arg > Max_Criteria do return -1
    n, m := int(n_arg), int(m_arg)
    if length != c.size_t(3 + m + n * m) do return -1
    for j := 0; j < m; j += 1 { if input[3 + j] < -Max_Value || input[3 + j] > Max_Value do return -1 }
    for i := 0; i < n * m; i += 1 { if input[3 + m + i] < -Max_Value || input[3 + m + i] > Max_Value do return -1 }
    best_score: i64 = 0
    best_index := 0
    for i := 0; i < n; i += 1 {
        score: i64 = 0
        for j := 0; j < m; j += 1 {
            product := input[3 + m + i * m + j] * input[3 + j]
            if method == 0 { score += product }
            else if j == 0 || product < score { score = product }
        }
        if i == 0 || score > best_score { best_score = score; best_index = i }
    }
    return i64(best_index)
}
