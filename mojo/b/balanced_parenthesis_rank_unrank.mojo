# Clean-room completion-count dynamic programming for Dyck-word rank/unrank.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("balanced_parenthesis_rank_unrank")
fn balanced_parenthesis_rank_unrank(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 22: return -1
    let mode = input[0]
    let pair_value = input[1]
    if pair_value < 1 or pair_value > 10: return -1
    let pairs = Int(pair_value)
    let sequence_length = 2 * pairs
    if mode == 0:
        if length != c_size_t(2 + sequence_length): return -1
        var balance = 0
        for i in range(sequence_length):
            let symbol = input[2 + i]
            if symbol != 0 and symbol != 1: return -1
            if symbol == 0: balance += 1
            else: balance -= 1
            if balance < 0: return -1
        if balance != 0: return -1
    elif mode == 1:
        if length != 3: return -1
    else:
        return -1

    var ways = List[Int64](capacity=231)
    for _ in range(231): ways.append(0)
    ways[0] = 1
    for remaining in range(1, sequence_length + 1):
        for balance in range(pairs + 1):
            var count = Int64(0)
            if balance < pairs: count += ways[(remaining - 1) * 11 + balance + 1]
            if balance > 0: count += ways[(remaining - 1) * 11 + balance - 1]
            ways[remaining * 11 + balance] = count

    if mode == 0:
        var rank = Int64(0)
        var balance = 0
        for i in range(sequence_length):
            let symbol = input[2 + i]
            let remaining = sequence_length - i - 1
            if symbol == 1 and balance < pairs: rank += ways[remaining * 11 + balance + 1]
            if symbol == 0: balance += 1
            else: balance -= 1
        return rank

    var rank = input[2]
    if rank < 0 or rank >= ways[sequence_length * 11]: return -1
    var balance = 0
    var code = Int64(0)
    for i in range(sequence_length):
        let remaining = sequence_length - i - 1
        let opening_count = if balance < pairs: ways[remaining * 11 + balance + 1] else: Int64(0)
        var symbol = Int64(0)
        if rank < opening_count: balance += 1
        else:
            rank -= opening_count
            symbol = 1
            balance -= 1
        code = (code << 1) | symbol
    return code
