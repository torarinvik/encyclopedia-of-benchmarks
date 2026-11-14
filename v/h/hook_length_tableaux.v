// Independent hook-length count; see package README.
module hook_length_tableaux
const prime = i64(998244353)

@[export: 'hook_length_tableaux']
pub fn hook_length_tableaux(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length == 0 || input[0] < 0 || input[0] > 65536 { return -1 }
        rows := int(input[0])
        if length != usize(rows + 1) { return -1 }
        mut total := i64(0)
        mut previous := i64(1000000)
        for i in 1 .. rows + 1 {
            width := input[i]
            if width < 1 || width > previous { return -1 }
            total += width
            if total > 1000000 { return -1 }
            previous = width
        }
        mut hooks := i64(1)
        mut height := rows
        if rows > 0 {
            for col := i64(0); col < input[1]; col++ {
                for height > 0 && input[height] <= col { height-- }
                for row in 0 .. height {
                    hooks = hooks * (input[row + 1] - col + i64(height - row - 1)) % prime
                }
            }
        }
        mut factorial := i64(1)
        for i := i64(2); i <= total; i++ { factorial = factorial * i % prime }
        mut inverse := i64(1)
        mut exponent := prime - 2
        for exponent > 0 {
            if exponent & 1 != 0 { inverse = inverse * hooks % prime }
            hooks = hooks * hooks % prime
            exponent >>= 1
        }
        return factorial * inverse % prime
    }
}
