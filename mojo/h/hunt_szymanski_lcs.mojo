from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("hunt_szymanski_lcs")
fn hunt_szymanski_lcs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 131:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 0 or n_value > 64 or m_value < 0 or m_value > 64:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + n_value + m_value):
        return -1
    for i in range(n + m):
        if input[2 + i] < 0 or input[2 + i] > 127:
            return -1

    var right_positions = InlineArray[Int32, 8192](fill=0)
    var position_count = InlineArray[Int32, 128](fill=0)
    var tails = InlineArray[Int32, 64](fill=0)
    for j in range(m):
        let symbol = Int(input[2 + n + j])
        let count = Int(position_count[symbol])
        right_positions[symbol * 64 + count] = Int32(j)
        position_count[symbol] = Int32(count + 1)

    var tail_count = 0
    for i in range(n):
        let symbol = Int(input[2 + i])
        var count = Int(position_count[symbol])
        while count > 0:
            count -= 1
            let position = right_positions[symbol * 64 + count]
            var low = 0
            var high = tail_count
            while low < high:
                let middle = low + (high - low) // 2
                if tails[middle] >= position:
                    high = middle
                else:
                    low = middle + 1
            if low == tail_count:
                tails[tail_count] = position
                tail_count += 1
            else:
                tails[low] = position
    return Int64(tail_count)
