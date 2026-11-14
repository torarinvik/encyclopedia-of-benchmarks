# Independent bounded FM-index display profile; see package rights note.
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

@export("fm_index_display")
fn fm_index_display(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 36: return -1
    let nv = input[0]
    if nv < 1 or nv > 32 or length != c_size_t(nv+4): return -1
    let n = Int(nv)
    let lv = input[n+1]
    let rv = input[n+2]
    let sv = input[n+3]
    if lv < 0 or rv < lv or rv >= nv or sv < 1 or sv > nv: return -1
    let left = Int(lv)
    let right = Int(rv)
    let stride = Int(sv)
    var text = List[Int64](capacity=n+1)
    for i in range(n):
        let value = input[1+i]
        if value < 1 or value > 4: return -1
        text.append(value)
    text.append(0)
    let size = n+1
    var sa = List[Int](capacity=size)
    for i in range(size): sa.append(i)
    for i in range(1,size):
        let key = sa[i]
        var j = i
        while j > 0 and suffix_less(text,key,sa[j-1]):
            sa[j] = sa[j-1]
            j -= 1
        sa[j] = key
    var isa = List[Int](capacity=size)
    var bwt = List[Int](capacity=size)
    var freq = List[Int](capacity=5)
    var first = List[Int](capacity=5)
    var seen = List[Int](capacity=5)
    for _ in range(size): isa.append(0)
    for _ in range(5):
        freq.append(0)
        first.append(0)
        seen.append(0)
    for row in range(size):
        isa[sa[row]] = row
        let symbol = Int(text[(sa[row]+size-1) % size])
        bwt.append(symbol)
        freq[symbol] += 1
    var sum = 0
    for symbol in range(5):
        first[symbol] = sum
        sum += freq[symbol]
    var lf = List[Int](capacity=size)
    for row in range(size):
        let symbol = bwt[row]
        lf.append(first[symbol]+seen[symbol])
        seen[symbol] += 1
    var sample = ((right+1) // stride+1)*stride-1
    if sample > n: sample = n
    var row = isa[sample]
    var current = sample
    while current > right+1:
        row = lf[row]
        current -= 1
    var reversed = List[UInt8](capacity=right-left+1)
    while current > left:
        reversed.append(UInt8(bwt[row]))
        row = lf[row]
        current -= 1
    let count = len(reversed)
    if count != right-left+1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2
    for i in range(count): output[i] = reversed[count-1-i]
    return Int64(count)
