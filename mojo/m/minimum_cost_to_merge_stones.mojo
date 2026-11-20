from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 30
const MAX_K = 30
const MAX_INPUT_LENGTH = 33
const DP_CELLS = MAX_N * MAX_N * (MAX_K + 1)
const INFINITY: Int64 = 1152921504606846976

fn mcs_index(left: Int, right: Int, piles: Int) -> Int:
    return (left * MAX_N + right) * (MAX_K + 1) + piles

@export("minimum_cost_to_merge_stones")
fn minimum_cost_to_merge_stones(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT_LENGTH: return -1
    if input[0] < 1 or input[0] > MAX_N or input[1] < 2 or input[1] > MAX_K: return -1
    let n = Int(input[0])
    let merge_count = Int(input[1])
    if Int(length) != n + 2: return -1

    var prefix = InlineArray[Int64, MAX_N + 1](fill=Int64(0))
    for i in range(n):
        let stone = input[i + 2]
        if stone < 1 or stone > 100: return -1
        prefix[i + 1] = prefix[i] + stone
    if (n - 1) % (merge_count - 1) != 0: return -1

    var dp = InlineArray[Int64, DP_CELLS](fill=INFINITY)
    for i in range(n): dp[mcs_index(i, i, 1)] = 0
    for interval_length in range(2, n + 1):
        for left in range(n - interval_length + 1):
            let right = left + interval_length - 1
            let maximum_piles = merge_count if merge_count < interval_length else interval_length
            for piles in range(2, maximum_piles + 1):
                var best = INFINITY
                for cut in range(left, right):
                    let first = dp[mcs_index(left, cut, 1)]
                    let rest = dp[mcs_index(cut + 1, right, piles - 1)]
                    if first < INFINITY and rest < INFINITY and first + rest < best:
                        best = first + rest
                dp[mcs_index(left, right, piles)] = best
            if interval_length >= merge_count:
                let to_k = dp[mcs_index(left, right, merge_count)]
                if to_k < INFINITY:
                    dp[mcs_index(left, right, 1)] = to_k + prefix[right + 1] - prefix[left]
    let answer = dp[mcs_index(0, n - 1, 1)]
    return -1 if answer >= INFINITY else answer
