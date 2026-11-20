from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 64
comptime MAX_INPUT = 195

fn suffix_less(s: List[Int64], total: Int, a0: Int, b0: Int) -> Bool:
    var a = a0
    var b = b0
    while a < total and b < total:
        if s[a] != s[b]: return s[a] < s[b]
        a += 1
        b += 1
    return a == total and b != total

fn rank_before(bwt: List[Int], end_at: Int, symbol: Int) -> Int:
    var count = 0
    for i in range(end_at):
        if bwt[i] == symbol: count += 1
    return count

@export("bidirectional_fm_index")
fn bidirectional_fm_index(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT): return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 0 or n64 > MAX_TEXT or q64 < 0 or q64 > 64: return -1
    let n = Int(n64)
    let q = Int(q64)
    if length != c_size_t(2 + n + 2 * q): return -1

    var forward_text = List[Int64](capacity=n + 1)
    var reverse_text = List[Int64](capacity=n + 1)
    for i in range(n):
        let symbol = input[2 + i]
        if symbol < 1 or symbol > 4: return -1
        forward_text.append(symbol)
        reverse_text.append(input[2 + n - 1 - i])
    forward_text.append(0)
    reverse_text.append(0)
    for op in range(q):
        let side = input[2 + n + 2 * op]
        let symbol = input[3 + n + 2 * op]
        if (side != 0 and side != 1) or symbol < 1 or symbol > 4: return -1

    let total = n + 1
    var forward_sa = List[Int](capacity=total)
    var reverse_sa = List[Int](capacity=total)
    for i in range(total):
        forward_sa.append(i)
        reverse_sa.append(i)
    for i in range(1, total):
        let key = forward_sa[i]
        var j = i
        while j > 0 and suffix_less(forward_text, total, key, forward_sa[j - 1]):
            forward_sa[j] = forward_sa[j - 1]
            j -= 1
        forward_sa[j] = key
        let reverse_key = reverse_sa[i]
        j = i
        while j > 0 and suffix_less(reverse_text, total, reverse_key, reverse_sa[j - 1]):
            reverse_sa[j] = reverse_sa[j - 1]
            j -= 1
        reverse_sa[j] = reverse_key

    var forward_bwt = List[Int](capacity=total)
    var reverse_bwt = List[Int](capacity=total)
    var forward_frequency = List[Int](capacity=5)
    var reverse_frequency = List[Int](capacity=5)
    for _ in range(5):
        forward_frequency.append(0)
        reverse_frequency.append(0)
    for i in range(total):
        let f_symbol = Int(forward_text[(forward_sa[i] + total - 1) % total])
        let r_symbol = Int(reverse_text[(reverse_sa[i] + total - 1) % total])
        forward_bwt.append(f_symbol)
        reverse_bwt.append(r_symbol)
        forward_frequency[f_symbol] += 1
        reverse_frequency[r_symbol] += 1
    var forward_c = List[Int](capacity=5)
    var reverse_c = List[Int](capacity=5)
    var seen = 0
    for symbol in range(5):
        forward_c.append(seen)
        seen += forward_frequency[symbol]
    seen = 0
    for symbol in range(5):
        reverse_c.append(seen)
        seen += reverse_frequency[symbol]

    var fl = 0
    var fr = total
    var rl = 0
    var rr = total
    var checksum: Int64 = 0
    for op in range(q):
        let side = Int(input[2 + n + 2 * op])
        let symbol = Int(input[3 + n + 2 * op])
        let old_fl = fl
        let old_fr = fr
        let old_rl = rl
        let old_rr = rr
        if side == 0:
            fl = forward_c[symbol] + rank_before(forward_bwt, old_fl, symbol)
            fr = forward_c[symbol] + rank_before(forward_bwt, old_fr, symbol)
            var start = old_rl
            for smaller in range(symbol):
                start += rank_before(forward_bwt, old_fr, smaller) - rank_before(forward_bwt, old_fl, smaller)
            let count = rank_before(forward_bwt, old_fr, symbol) - rank_before(forward_bwt, old_fl, symbol)
            rl = start
            rr = start + count
        else:
            rl = reverse_c[symbol] + rank_before(reverse_bwt, old_rl, symbol)
            rr = reverse_c[symbol] + rank_before(reverse_bwt, old_rr, symbol)
            var start = old_fl
            for smaller in range(symbol):
                start += rank_before(reverse_bwt, old_rr, smaller) - rank_before(reverse_bwt, old_rl, smaller)
            let count = rank_before(reverse_bwt, old_rr, symbol) - rank_before(reverse_bwt, old_rl, symbol)
            fl = start
            fr = start + count
        checksum += Int64(op + 1) * Int64(fr - fl)
    return checksum
