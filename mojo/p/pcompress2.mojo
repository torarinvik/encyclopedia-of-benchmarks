# Independent bounded FreeBench pcompress2 pipeline; provenance in package README.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn pcompress_rotation_less(data: List[Int], a: Int, b: Int) -> Bool:
    let n = len(data)
    for i in range(n):
        let x = data[(a+i)%n]; let y = data[(b+i)%n]
        if x != y: return x < y
    return a < b

fn pcompress_emit(mut bytes: List[UInt8], mut state: List[Int], bit: Int):
    state[2] >>= 1
    if bit != 0: state[2] |= 128
    state[3] -= 1
    if state[3] == 0:
        bytes.append(UInt8(state[2]))
        state[3] = 8

fn pcompress_follow(mut bytes: List[UInt8], mut state: List[Int], bit: Int):
    pcompress_emit(bytes,state,bit)
    while state[4] > 0:
        pcompress_emit(bytes,state,1-bit)
        state[4] -= 1

fn pcompress_symbol(symbol: Int, cum: List[Int], mut state: List[Int], mut bytes: List[UInt8]):
    let span = state[1]-state[0]+1
    let old_low = state[0]
    state[1] = old_low+(span*cum[symbol-1])//cum[0]-1
    state[0] = old_low+(span*cum[symbol])//cum[0]
    while True:
        if state[1] < 32768: pcompress_follow(bytes,state,0)
        elif state[0] >= 32768:
            pcompress_follow(bytes,state,1)
            state[0] -= 32768; state[1] -= 32768
        elif state[0] >= 16384 and state[1] < 49152:
            state[4] += 1; state[0] -= 16384; state[1] -= 16384
        else: break
        state[0] *= 2; state[1] = 2*state[1]+1

@export("pcompress2")
fn pcompress2(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let nv = input[0]
    if nv < 1 or nv > 32 or length != c_size_t(nv+1): return -1
    let n = Int(nv)
    var data = List[Int](capacity=n)
    var order = List[Int](capacity=n)
    for i in range(n):
        let value = input[i+1]
        if value < 0 or value > 255: return -1
        data.append(Int(value)); order.append(i)
    for i in range(1,n):
        let item = order[i]
        var j = i
        while j > 0 and pcompress_rotation_less(data,item,order[j-1]):
            order[j] = order[j-1]
            j -= 1
        order[j] = item
    var last = List[Int](capacity=n)
    var primary = 0
    for i in range(n):
        if order[i] == 0: primary = i
        last.append(data[(order[i]+n-1)%n])
    var rle = List[Int](capacity=2*n)
    var at = 0
    while at < n:
        let value = last[at]
        var count = 1
        while at+count < n and last[at+count] == value and count < 127: count += 1
        if count == 1:
            while at+count < n and last[at+count-1] != last[at+count] and (at+count+1 == n or last[at+count] != last[at+count+1]): count += 1
            rle.append(count & 127)
            for i in range(count): rle.append(last[at+i])
        else:
            rle.append(count | 128); rle.append(value)
        at += count
    var char_index = List[Int](capacity=256)
    var index_char = List[Int](length=258, fill=0)
    var freq = List[Int](length=258, fill=1)
    var cum = List[Int](capacity=258)
    for i in range(256): char_index.append(i+1); index_char[i+1] = i
    for i in range(258): cum.append(257-i)
    freq[0] = 0
    # state = low, high, bit buffer, remaining bit slots, deferred bits.
    var state = List[Int](capacity=5)
    state.append(0); state.append(65535); state.append(0); state.append(8); state.append(0)
    var stream = List[UInt8](capacity=512)
    for byte in rle:
        let symbol = char_index[byte]
        pcompress_symbol(symbol,cum,state,stream)
        if cum[0] == 16383:
            var total = 0
            for reverse_i in range(258):
                let i = 257-reverse_i
                freq[i] = (freq[i]+1)//2
                cum[i] = total
                total += freq[i]
        var i = symbol
        while freq[i] == freq[i-1]: i -= 1
        if i < symbol:
            let a = index_char[i]; let b = index_char[symbol]
            index_char[i] = b; index_char[symbol] = a
            char_index[a] = symbol; char_index[b] = i
        freq[i] += 1
        while i > 0:
            i -= 1
            cum[i] += 1
    pcompress_symbol(257,cum,state,stream)
    state[4] += 1
    var final_bit = 0
    if state[0] >= 16384: final_bit = 1
    pcompress_follow(stream,state,final_bit)
    stream.append(UInt8(state[2] >> state[3]))
    let bytes = 8+len(stream)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(8): output[i] = 0
    output[0] = UInt8(n); output[4] = UInt8(primary)
    for i in range(len(stream)): output[8+i] = stream[i]
    return Int64(bytes)
