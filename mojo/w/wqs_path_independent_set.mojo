# Uncompiled and unexecuted weighted-binary-search draft.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn evaluate(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, penalty: Int64) -> Tuple[Int64, Int64]:
    var two_score: Int64 = 0
    var two_count: Int64 = 0
    var one_score: Int64 = 0
    var one_count: Int64 = 0
    for i in range(n):
        let take_score = two_score+input[2+i]-penalty
        let take_count = two_count+1
        var score = one_score
        var count = one_count
        if take_score > one_score or (take_score == one_score and take_count > one_count):
            score = take_score
            count = take_count
        two_score = one_score
        two_count = one_count
        one_score = score
        one_count = count
    return (one_score, one_count)

@export("wqs_path_independent_set")
fn wqs_path_independent_set(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1000000000
    if input[0] < 0 or input[0] > 128 or input[1] < 0 or input[1] > (input[0]+1)//2: return -1000000000
    let n = Int(input[0])
    if length != c_size_t(n+2): return -1000000000
    for i in range(n):
        if input[2+i] < -1000 or input[2+i] > 1000: return -1000000000
    var low: Int64 = -256001
    var high: Int64 = 256001
    while low < high:
        let middle = low+(high-low+1)//2
        let state = evaluate(input, n, middle)
        if state[1] >= input[1]: low = middle
        else: high = middle-1
    let state = evaluate(input, n, low)
    return state[0]+low*input[1]
