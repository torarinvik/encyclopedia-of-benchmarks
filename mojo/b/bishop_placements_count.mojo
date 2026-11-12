from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias MAX_K = 16
alias MAX_DIAGONALS = 2 * MAX_N

fn bpc_diagonal_size(index: Int) -> Int:
    if index % 2 == 1:
        return (index // 4) * 2 + 1
    return ((index - 1) // 4) * 2 + 2

fn bpc_color_counts(k: Int, last_diagonal: Int) -> InlineArray[Int64, MAX_K + 1]:
    var dp = InlineArray[Int64, MAX_DIAGONALS * (MAX_K + 1)]()
    dp[0] = 1
    dp[MAX_K + 1] = 1
    if k >= 1:
        dp[MAX_K + 2] = 1
    for diagonal in range(2, last_diagonal + 1):
        dp[diagonal * (MAX_K + 1)] = 1
        let squares = bpc_diagonal_size(diagonal)
        for placed in range(1, k + 1):
            let offset = diagonal * (MAX_K + 1) + placed
            let previous = (diagonal - 2) * (MAX_K + 1)
            dp[offset] = dp[previous + placed] + dp[previous + placed - 1] * Int64(squares - placed + 1)
    var counts = InlineArray[Int64, MAX_K + 1]()
    for placed in range(k + 1):
        counts[placed] = dp[last_diagonal * (MAX_K + 1) + placed]
    return counts

@export("bishop_placements_count")
fn bishop_placements_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2:
        return -1
    if input[0] < 1 or input[0] > MAX_N or input[1] < 0 or input[1] > MAX_K:
        return -1
    let n = Int(input[0])
    let k = Int(input[1])
    let maximum = if n == 1: 1 else: 2 * n - 2
    if k > maximum:
        return 0
    let black = bpc_color_counts(k, 2 * n - 1)
    let white = bpc_color_counts(k, 2 * n - 2)
    var result: Int64 = 0
    for left in range(k + 1):
        result += black[left] * white[k - left]
    return result
