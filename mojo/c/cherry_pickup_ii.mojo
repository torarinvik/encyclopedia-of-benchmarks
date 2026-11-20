from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_DIM = 6
comptime MAX_INPUT = 39
comptime STATES = 36

@export("cherry_pickup_ii")
fn cherry_pickup_ii(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(6) or length > c_size_t(MAX_INPUT):
        return -1
    let rows = Int(input[0])
    let columns = Int(input[1])
    if rows < 2 or rows > MAX_DIM or columns < 2 or columns > MAX_DIM or Int(length) != 2 + rows * columns:
        return -1
    for i in range(rows * columns):
        if input[2 + i] < 0 or input[2 + i] > 100:
            return -1
    var previous = InlineArray[Int64, 36](fill=-1)
    var current = InlineArray[Int64, 36](fill=-1)
    previous[columns - 1] = input[2] + input[2 + columns - 1]
    for row in range(1, rows):
        for i in range(STATES): current[i] = -1
        for left in range(columns):
            for right in range(columns):
                let score = previous[left * columns + right]
                if score < 0:
                    continue
                for dl in range(-1, 2):
                    let next_left = left + dl
                    if next_left < 0 or next_left >= columns:
                        continue
                    for dr in range(-1, 2):
                        let next_right = right + dr
                        if next_right < 0 or next_right >= columns:
                            continue
                        var candidate = score + input[2 + row * columns + next_left]
                        if next_left != next_right:
                            candidate += input[2 + row * columns + next_right]
                        let slot = next_left * columns + next_right
                        current[slot] = max(current[slot], candidate)
        for i in range(STATES): previous[i] = current[i]
    var answer: Int64 = -1
    for left in range(columns):
        for right in range(columns): answer = max(answer, previous[left * columns + right])
    return answer
