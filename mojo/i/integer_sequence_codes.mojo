# Bounded independently written code modes; see package RIGHTS.md.
from std.collections import InlineArray, List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn isc_log2(mut value: Int) -> Int:
    var exponent = -1
    while value > 0:
        exponent += 1
        value >>= 1
    return exponent

fn isc_number(mut bits: List[UInt8], value: Int, width: Int):
    var position = width
    while position > 0:
        position -= 1
        bits.append(UInt8((value >> position) & 1))

fn isc_unary(mut bits: List[UInt8], value: Int):
    for _ in range(value): bits.append(1)
    bits.append(0)

fn isc_minimal(mut bits: List[UInt8], value: Int, universe: Int):
    if universe == 1: return
    let width = isc_log2(universe)
    let short_count = (1 << (width+1)) - universe
    if value < short_count: isc_number(bits, value, width)
    else: isc_number(bits, value+short_count, width+1)

fn isc_gamma(mut bits: List[UInt8], value: Int):
    let shifted = value+1
    let width = isc_log2(shifted)
    isc_unary(bits, width)
    isc_number(bits, shifted-(1 << width), width)

fn isc_interpolate(mut bits: List[UInt8], values: InlineArray[Int, 32],
                   left: Int, right: Int, low: Int, high: Int):
    if left >= right: return
    let middle = left+(right-left-1)//2
    let lower = low+middle-left
    let upper = high-(right-middle-1)
    let value = values[middle]
    isc_minimal(bits, value-lower, upper-lower)
    isc_interpolate(bits, values, left, middle, low, value)
    isc_interpolate(bits, values, middle+1, right, value+1, high)

@export("integer_sequence_codes")
fn integer_sequence_codes(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 35: return -1
    let mv = input[0]; let nv = input[1]; let pv = input[2]
    if mv < 0 or mv > 9 or nv < 1 or nv > 32 or length != c_size_t(nv+3): return -1
    let mode = Int(mv); let n = Int(nv)
    if mode == 0 or mode == 2 or mode == 3 or mode == 7 or mode == 8:
        if pv != 0: return -1
    elif mode == 1:
        if pv < 2 or pv > 1000000: return -1
    elif mode == 4:
        if pv < 1 or pv > 128: return -1
    elif mode == 5 or mode == 6:
        if pv < 2 or pv > 4096 or nv > pv: return -1
    else:
        if pv < 1 or pv > 20: return -1
    let parameter = Int(pv)
    var values = InlineArray[Int, 32](fill=0)
    for i in range(n):
        let x = input[3+i]
        if x < 0: return -1
        if mode == 0 and x > 31: return -1
        if mode == 1 and x >= pv: return -1
        if (mode == 2 or mode == 3 or mode == 7 or mode == 9) and x > 1000000: return -1
        if mode == 4 and x > 127: return -1
        if mode == 8 and x >= (1 << 28): return -1
        if mode == 5 or mode == 6:
            if x >= pv or (i > 0 and x <= input[2+i]): return -1
        values[i] = Int(x)
    var bits = List[UInt8](capacity=4096)
    var direct = List[UInt8](capacity=512)
    if mode == 0:
        for i in range(n): isc_unary(bits, values[i])
    elif mode == 1:
        for i in range(n): isc_minimal(bits, values[i], parameter)
    elif mode == 2 or mode == 3:
        for i in range(n):
            if mode == 2: isc_gamma(bits, values[i])
            else:
                let width = isc_log2(values[i]+1)
                isc_gamma(bits, width)
                isc_number(bits, values[i]+1-(1 << width), width)
    elif mode == 4:
        for i in range(n):
            isc_unary(bits, values[i]//parameter)
            isc_minimal(bits, values[i]%parameter, parameter)
    elif mode == 5:
        var width = 0
        while n*(1 << (width+1)) <= parameter: width += 1
        let bucket_size = 1 << width
        let bucket_count = (parameter+bucket_size-1)//bucket_size
        var counts = InlineArray[Int, 4096](fill=0)
        for i in range(n): counts[values[i]//bucket_size] += 1
        for bucket in range(bucket_count): isc_unary(bits, counts[bucket])
        for i in range(n): isc_number(bits, values[i]%bucket_size, width)
    elif mode == 6:
        isc_interpolate(bits, values, 0, n, 0, parameter)
    elif mode == 7:
        for i in range(n):
            let value = values[i]
            var shift = max(0, isc_log2(value))//7*7
            while True:
                var byte = UInt8((value >> shift) & 127)
                if shift > 0: byte |= 128
                direct.append(byte)
                if shift == 0: break
                shift -= 7
    elif mode == 8:
        var slots = InlineArray[Int, 9]()
        slots[0]=28; slots[1]=14; slots[2]=9; slots[3]=7; slots[4]=5
        slots[5]=4; slots[6]=3; slots[7]=2; slots[8]=1
        var widths = InlineArray[Int, 9]()
        widths[0]=1; widths[1]=2; widths[2]=3; widths[3]=4; widths[4]=5
        widths[5]=7; widths[6]=9; widths[7]=14; widths[8]=28
        var position = 0
        while position < n:
            var selector = 0
            var take = 0
            while selector < 9:
                take = min(slots[selector], n-position)
                var fits = True
                for i in range(take):
                    if values[position+i] >= (1 << widths[selector]): fits = False
                if fits: break
                selector += 1
            let width = widths[selector]
            var word = selector << 28
            for i in range(take): word |= values[position+i] << (28-width*(i+1))
            isc_number(bits, word, 32)
            position += take
    else:
        let limit = 1 << parameter
        var exceptions = 0
        for i in range(n):
            isc_number(bits, values[i] & (limit-1), parameter)
            if values[i] >= limit: exceptions += 1
        isc_number(bits, exceptions, 6)
        var index_width = 0
        while (1 << index_width) < n: index_width += 1
        for i in range(n):
            if values[i] >= limit:
                isc_number(bits, i, index_width)
                isc_number(bits, values[i], 20)
    if mode != 7:
        for i in range((len(bits)+7)//8):
            var byte = UInt8(0)
            for b in range(8):
                let index = 8*i+b
                if index < len(bits) and bits[index] != 0: byte |= UInt8(1 << (7-b))
            direct.append(byte)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(direct)): return -2
    for i in range(len(direct)): output[i] = direct[i]
    return Int64(len(direct))
