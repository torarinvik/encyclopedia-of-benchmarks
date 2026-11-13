from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("bounded_knapsack_monotone_queue")
fn bounded_knapsack_monotone_queue(packed: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if packed == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 51:
        return -1
    if packed[0] < 0 or packed[0] > 64 or packed[1] < 0 or packed[1] > 16:
        return -1
    let capacity = Int(packed[0])
    let types = Int(packed[1])
    if length != c_size_t(2 + 3 * types):
        return -1
    for item in range(types):
        let weight = packed[2 + 3 * item]
        let value = packed[3 + 3 * item]
        let count = packed[4 + 3 * item]
        if weight < 1 or weight > 16 or value < 0 or value > 100 or count < 0 or count > 16:
            return -1

    var dp = InlineArray[Int64, 65](fill=0)
    var next = InlineArray[Int64, 65](fill=0)
    var queue_score = InlineArray[Int64, 65](fill=0)
    var queue_index = InlineArray[Int, 65](fill=0)
    for item in range(types):
        let weight = Int(packed[2 + 3 * item])
        let value = packed[3 + 3 * item]
        let count = Int(packed[4 + 3 * item])
        for residue in range(min(weight, capacity + 1)):
            var head = 0
            var tail = 0
            let max_t = (capacity - residue) // weight
            for t in range(max_t + 1):
                let current = residue + t * weight
                let score = dp[current] - Int64(t) * value
                while tail > head and queue_score[tail - 1] <= score:
                    tail -= 1
                queue_index[tail] = t
                queue_score[tail] = score
                tail += 1
                let first_allowed = max(0, t - count)
                while head < tail and queue_index[head] < first_allowed:
                    head += 1
                next[current] = Int64(t) * value + queue_score[head]
        for c in range(capacity + 1):
            dp[c] = next[c]
    return dp[capacity]
