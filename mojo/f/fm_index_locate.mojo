# Independent bounded FM-index locate profile; see package rights note.
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

@export("fm_index_locate")
fn fm_index_locate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 43: return -1
    let nv = input[0]
    if nv < 1 or nv > 32 or length < c_size_t(nv+4): return -1
    let n = Int(nv)
    let mv = input[n+1]
    if mv < 1 or mv > 8 or length != c_size_t(n+3+mv): return -1
    let m = Int(mv)
    let stridev = input[n+2+m]
    if stridev < 1 or stridev > nv: return -1
    let stride = Int(stridev)
    var text = List[Int64](capacity=n+1)
    var pattern = List[Int64](capacity=m)
    for i in range(n):
        let v = input[1+i]
        if v < 1 or v > 4: return -1
        text.append(v)
    text.append(0)
    for i in range(m):
        let v = input[n+2+i]
        if v < 1 or v > 4: return -1
        pattern.append(v)
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
    for row in range(total):
        let symbol = Int(text[(sa[row]+total-1) % total])
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
    var lf = List[Int](capacity=total)
    for row in range(total):
        var rank = 0
        for i in range(row):
            if bwt[i] == bwt[row]: rank += 1
        lf.append(starts[bwt[row]]+rank)
    var offsets = List[Int64](capacity=n)
    for origin in range(left,right):
        var row = origin
        var steps = 0
        while sa[row] % stride != 0 and steps < total:
            row = lf[row]
            steps += 1
        if sa[row] % stride != 0: return -1
        let position = (sa[row]+steps) % total
        if position >= n: return -1
        offsets.append(Int64(position))
    let bytes = 8*(1+len(offsets))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    let count = Int64(len(offsets))
    for byte in range(8): output[byte] = UInt8((count >> (8*byte)) & 255)
    for i in range(len(offsets)):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((offsets[i] >> (8*byte)) & 255)
    return Int64(bytes)
