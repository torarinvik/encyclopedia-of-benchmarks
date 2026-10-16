module lyndon_factorization

const max_sequence_length = 256

@[export: 'lyndon_factorization']
pub fn lyndon_factorization(input &i64, length usize, output &u8, capacity usize) i64 {
    if length < 1 || length > max_sequence_length + 1 { return -1 }
    unsafe {
        if input == nil || input[0] < 0 || input[0] > max_sequence_length || length != usize(input[0]) + 1 { return -1 }
        n := usize(input[0])
        for i in 0 .. n { if input[i + 1] < 97 || input[i + 1] > 122 { return -1 } }
        required := 2 * n
        if capacity < required || (required != 0 && output == nil) { return -2 }
        mut start := usize(0)
        mut out := usize(0)
        for start < n {
            mut candidate := start + 1
            mut matched := start
            for candidate < n && input[matched + 1] <= input[candidate + 1] {
                if input[matched + 1] < input[candidate + 1] { matched = start } else { matched++ }
                candidate++
            }
            factor_length := candidate - matched
            for start <= matched {
                for j in 0 .. factor_length { output[out] = u8(input[start + j + 1]); out++ }
                output[out] = 0; out++
                start += factor_length
            }
        }
        return i64(out)
    }
}
