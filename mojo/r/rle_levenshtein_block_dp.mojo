# Run-length-native Levenshtein block dynamic program.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("rle_levenshtein_block_dp")
fn rle_levenshtein_block_dp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 18: return -1
    let lc = input[0]
    if lc < 1 or lc > 4: return -1
    let left_count = Int(lc)
    let ri = 1+2*left_count
    if c_size_t(ri) >= length: return -1
    let rc = input[ri]
    if rc < 1 or rc > 4 or length != c_size_t(ri+1+2*Int(rc)): return -1
    let right_count = Int(rc)
    var ls = List[Int64](capacity=left_count)
    var ll = List[Int](capacity=left_count)
    var rs = List[Int64](capacity=right_count)
    var rl = List[Int](capacity=right_count)
    var total = 0
    for i in range(left_count):
        let symbol = input[1+2*i]; let size = input[2+2*i]
        if symbol < 0 or symbol > 3 or size < 1 or size > 8: return -1
        total += Int(size)
        if total > 16: return -1
        ls.append(symbol); ll.append(Int(size))
    total = 0
    for i in range(right_count):
        let symbol = input[ri+1+2*i]; let size = input[ri+2+2*i]
        if symbol < 0 or symbol > 3 or size < 1 or size > 8: return -1
        total += Int(size)
        if total > 16: return -1
        rs.append(symbol); rl.append(Int(size))
    var bottom = List[Int64](capacity=36)
    var next_bottom = List[Int64](capacity=36)
    for _ in range(36): bottom.append(0); next_bottom.append(0)
    var right_prefix = 0
    for j in range(right_count):
        for column in range(rl[j]+1): bottom[9*j+column] = Int64(right_prefix+column)
        right_prefix += rl[j]
    var left_prefix = 0
    for i in range(left_count):
        let rows = ll[i]
        var boundary = List[Int64](capacity=9)
        for row in range(9): boundary.append(Int64(left_prefix+row))
        for j in range(right_count):
            let columns = rl[j]
            var previous = List[Int64](capacity=9)
            var current = List[Int64](capacity=9)
            var right = List[Int64](capacity=9)
            for column in range(9):
                previous.append(bottom[9*j+column]); current.append(0); right.append(0)
            right[0] = previous[columns]
            for row in range(1,rows+1):
                current[0] = boundary[row]
                for column in range(1,columns+1):
                    var value = previous[column]+1
                    if current[column-1]+1 < value: value = current[column-1]+1
                    var substitution = Int64(1)
                    if ls[i] == rs[j]: substitution = 0
                    if previous[column-1]+substitution < value: value = previous[column-1]+substitution
                    current[column] = value
                right[row] = current[columns]
                for column in range(columns+1): previous[column] = current[column]
            for column in range(columns+1): next_bottom[9*j+column] = previous[column]
            for row in range(rows+1): boundary[row] = right[row]
        for j in range(right_count):
            for column in range(rl[j]+1): bottom[9*j+column] = next_bottom[9*j+column]
        left_prefix += rows
    return bottom[9*(right_count-1)+rl[right_count-1]]
