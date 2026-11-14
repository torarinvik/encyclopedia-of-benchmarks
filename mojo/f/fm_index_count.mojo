# Independent bounded FM-index count profile; see package rights note.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn suffix_less(text: List[Int64], a: Int, b: Int) -> Bool:
    var i = a
    var j = b
    while i < len(text) and j < len(text):
        if text[i] != text[j]: return text[i] < text[j]
        i += 1
        j += 1
    return i == len(text) and j != len(text)

@export("fm_index_count")
fn fm_index_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 42: return -1
    let nv = input[0]
    if nv < 1 or nv > 32 or length < c_size_t(nv+3): return -1
    let n = Int(nv)
    let mv = input[n+1]
    if mv < 1 or mv > 8 or length != c_size_t(n+2+mv): return -1
    let m = Int(mv)
    var text = List[Int64](capacity=n+1)
    var pattern = List[Int64](capacity=m)
    for i in range(n):
        let value = input[1+i]
        if value < 1 or value > 4: return -1
        text.append(value)
    text.append(0)
    for i in range(m):
        let value = input[n+2+i]
        if value < 1 or value > 4: return -1
        pattern.append(value)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    let total = n+1
    var sa = List[Int](capacity=total)
    for i in range(total): sa.append(i)
    for i in range(1,total):
        let key = sa[i]
        var j = i
        while j > 0 and suffix_less(text,key,sa[j-1]):
            sa[j] = sa[j-1]
            j -= 1
        sa[j] = key
    var bwt = List[Int](capacity=total)
    var freq = List[Int](capacity=5)
    var starts = List[Int](capacity=5)
    for _ in range(5):
        freq.append(0)
        starts.append(0)
    for i in range(total):
        let symbol = Int(text[(sa[i]+total-1) % total])
        bwt.append(symbol)
        freq[symbol] += 1
    var prefix = 0
    for symbol in range(5):
        starts[symbol] = prefix
        prefix += freq[symbol]
    var left = 0
    var right = total
    var p = m-1
    while p >= 0:
        let symbol = Int(pattern[p])
        var rl = 0
        var rr = 0
        for i in range(left):
            if bwt[i] == symbol: rl += 1
        for i in range(right):
            if bwt[i] == symbol: rr += 1
        left = starts[symbol]+rl
        right = starts[symbol]+rr
        if left == right: break
        p -= 1
    let count = Int64(right-left)
    for byte in range(8): output[byte] = UInt8((count >> (8*byte)) & 255)
    return 8
