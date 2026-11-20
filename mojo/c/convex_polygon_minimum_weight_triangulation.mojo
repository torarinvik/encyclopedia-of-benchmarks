from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn convex_polygon_minimum_weight_triangulation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 37:
        return -1
    if input[0] < 3 or input[0] > 10:
        return -1
    let n = Int(input[0])
    var diagonal_count = 0
    for i in range(n):
        for j in range(i + 2, n):
            if not (i == 0 and j == n - 1):
                diagonal_count += 1
    if length != c_size_t(1 + diagonal_count):
        return -1

    var weight = InlineArray[Int64, 100](fill=0)
    var at = 1
    for i in range(n):
        for j in range(i + 2, n):
            if i == 0 and j == n - 1:
                continue
            let value = input[at]
            if value < 0 or value > 1000:
                return -1
            weight[i * 10 + j] = value
            at += 1

    var dp = InlineArray[Int64, 100](fill=0)
    for span in range(2, n):
        for left in range(n - span):
            let right = left + span
            var best: Int64 = 7001
            for split in range(left + 1, right):
                let left_edge: Int64 = if split - left == 1 then 0 else weight[left * 10 + split]
                let right_edge: Int64 = if right - split == 1 then 0 else weight[split * 10 + right]
                let candidate = dp[left * 10 + split] + dp[split * 10 + right] + left_edge + right_edge
                if candidate < best:
                    best = candidate
            dp[left * 10 + right] = best
    return dp[n - 1]
