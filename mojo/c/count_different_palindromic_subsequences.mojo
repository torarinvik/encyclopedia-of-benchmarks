from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_LENGTH = 20
alias MODULUS = 1_000_000_007

fn normalize(value: Int64) -> Int64:
    var result = value % MODULUS
    if result < 0: result += MODULUS
    return result

@export("count_different_palindromic_subsequences")
fn count_different_palindromic_subsequences(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 22: return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_LENGTH or length != c_size_t(n_value + 1): return -1
    let n = Int(n_value)
    var symbols = InlineArray[Int, MAX_LENGTH](fill=0)
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] > 3: return -1
        symbols[i] = Int(input[i + 1])
    if n == 0: return 0

    var next_equal = InlineArray[Int, MAX_LENGTH](fill=MAX_LENGTH)
    var previous_equal = InlineArray[Int, MAX_LENGTH](fill=-1)
    var next_at = InlineArray[Int, 4](fill=MAX_LENGTH)
    var previous_at = InlineArray[Int, 4](fill=-1)
    for i in range(n - 1, -1, -1):
        let symbol = symbols[i]
        next_equal[i] = next_at[symbol]
        next_at[symbol] = i
    for i in range(n):
        let symbol = symbols[i]
        previous_equal[i] = previous_at[symbol]
        previous_at[symbol] = i

    var dp = InlineArray[Int64, MAX_LENGTH * MAX_LENGTH](fill=0)
    for i in range(n): dp[i * MAX_LENGTH + i] = 1
    for width in range(2, n + 1):
        for left in range(n - width + 1):
            let right = left + width - 1
            let inner = if width > 2: dp[(left + 1) * MAX_LENGTH + right - 1] else: 0
            var value: Int64 = 0
            if symbols[left] != symbols[right]:
                value = dp[(left + 1) * MAX_LENGTH + right] + dp[left * MAX_LENGTH + right - 1] - inner
            else:
                let first = next_equal[left]
                let last = previous_equal[right]
                if first >= right or last <= left or first > last:
                    value = 2 * inner + 2
                elif first == last:
                    value = 2 * inner + 1
                else:
                    let duplicates = if first + 1 <= last - 1: dp[(first + 1) * MAX_LENGTH + last - 1] else: 0
                    value = 2 * inner - duplicates
            dp[left * MAX_LENGTH + right] = normalize(value)
    return dp[n - 1]
