from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_N = 256
comptime MAX_PARSEABLE_LENGTH = 258

fn eg_sift_down(
    inout degrees: InlineArray[Int64, MAX_N], root_start: Int, end: Int
):
    var root = root_start
    while root < end // 2:
        var child = root * 2 + 1
        if child + 1 < end and degrees[child] < degrees[child + 1]:
            child += 1
        if degrees[root] >= degrees[child]:
            break
        let temporary = degrees[root]
        degrees[root] = degrees[child]
        degrees[child] = temporary
        root = child

fn eg_sort_descending(inout degrees: InlineArray[Int64, MAX_N], count: Int):
    var start = count // 2
    while start > 0:
        start -= 1
        eg_sift_down(degrees, start, count)
    var ending = count
    while ending > 1:
        ending -= 1
        let temporary = degrees[0]
        degrees[0] = degrees[ending]
        degrees[ending] = temporary
        eg_sift_down(degrees, 0, ending)

    var left = 0
    var right = count - 1
    while left < right:
        let temporary = degrees[left]
        degrees[left] = degrees[right]
        degrees[right] = temporary
        left += 1
        right -= 1

@export("erdos_gallai_graphical_sequence")
fn erdos_gallai_graphical_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or
        length < c_size_t(1) or length > c_size_t(MAX_PARSEABLE_LENGTH):
        return -1
    let n_word = input[0]
    if n_word < 0 or n_word > Int64(MAX_N):
        return -1
    let n = Int(n_word)
    if length != c_size_t(n + 1):
        return -1

    var degrees = InlineArray[Int64, MAX_N]()
    var sum: Int64 = 0
    for index in range(n):
        let degree = input[index + 1]
        if degree < 0 or degree >= n_word:
            return -1
        degrees[index] = degree
        sum += degree

    if sum % 2 != 0:
        return 0
    if n == 0:
        return 1

    eg_sort_descending(degrees, n)
    var prefix = InlineArray[Int64, MAX_N + 1]()
    for index in range(n):
        prefix[index + 1] = prefix[index] + degrees[index]

    for k in range(1, n + 1):
        var low = k
        var high = n
        while low < high:
            let middle = low + (high - low) // 2
            if degrees[middle] >= Int64(k):
                low = middle + 1
            else:
                high = middle
        let split = low
        let k64 = Int64(k)
        let rhs = k64 * (k64 - 1) + Int64(split - k) * k64 +
                  prefix[n] - prefix[split]
        if prefix[k] > rhs:
            return 0
    return 1
