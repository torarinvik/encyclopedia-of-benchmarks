@[export: 'permutation_count']
pub fn permutation_count(input &i64, input_length usize) i64 {
    unsafe {
        if input == nil || input_length != 2 { return -1 }
        n := input[0]
        r := input[1]
        if n < 0 || n > 18 || r < 0 || r > 18 { return -1 }
        mut result := i64(1)
        if r > n {
            mut factor := i64(2)
            for factor <= n {
                result *= factor
                factor++
            }
        } else {
            mut i := i64(0)
            for i < r {
                result *= n - i
                i++
            }
        }
        return result
    }
}
