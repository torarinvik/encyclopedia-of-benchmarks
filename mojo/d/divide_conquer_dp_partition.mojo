from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime DCDP_MAX_N = 64
comptime DCDP_MAX_GROUPS = 8
comptime DCDP_MAX_INPUT = 66
comptime DCDP_STACK_CAPACITY = 136
comptime DCDP_INF: Int64 = 2305843009213693951

@export("divide_conquer_dp_partition")
fn divide_conquer_dp_partition(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > DCDP_MAX_INPUT:
        return -1
    let n_value = values[0]
    let groups_value = values[1]
    if n_value < 1 or n_value > DCDP_MAX_N or groups_value < 1 or
       groups_value > DCDP_MAX_GROUPS or groups_value > n_value or Int(length) != Int(n_value) + 2:
        return -1
    let n = Int(n_value)
    let groups = Int(groups_value)
    var prefix = InlineArray[Int64, 65](fill=0)
    var previous = InlineArray[Int64, 65](fill=DCDP_INF)
    var current = InlineArray[Int64, 65](fill=DCDP_INF)
    for i in range(n):
        let value = values[i + 2]
        if value < 0 or value > 1000: return -1
        prefix[i + 1] = prefix[i] + value
    previous[0] = 0

    for group in range(1, groups + 1):
        for i in range(n + 1): current[i] = DCDP_INF
        var stack_left = InlineArray[Int64, 136](fill=0)
        var stack_right = InlineArray[Int64, 136](fill=0)
        var stack_low = InlineArray[Int64, 136](fill=0)
        var stack_high = InlineArray[Int64, 136](fill=0)
        var top = 1
        stack_left[0] = group
        stack_right[0] = n
        stack_low[0] = group - 1
        stack_high[0] = n - 1
        while top > 0:
            top -= 1
            let left = Int(stack_left[top])
            let right = Int(stack_right[top])
            let opt_low = Int(stack_low[top])
            let opt_high = Int(stack_high[top])
            if left > right: continue
            let middle = left + (right - left) // 2
            let upper = min(opt_high, middle - 1)
            var best = DCDP_INF
            var best_split = opt_low
            for split in range(opt_low, upper + 1):
                if previous[split] == DCDP_INF: continue
                let segment = prefix[middle] - prefix[split]
                let candidate = previous[split] + segment * segment
                if candidate < best:
                    best = candidate
                    best_split = split
            current[middle] = best
            if middle < right:
                stack_left[top] = middle + 1
                stack_right[top] = right
                stack_low[top] = best_split
                stack_high[top] = opt_high
                top += 1
            if left < middle:
                stack_left[top] = left
                stack_right[top] = middle - 1
                stack_low[top] = opt_low
                stack_high[top] = best_split
                top += 1
        for i in range(n + 1):
            let temporary = previous[i]
            previous[i] = current[i]
            current[i] = temporary
    return previous[n]
