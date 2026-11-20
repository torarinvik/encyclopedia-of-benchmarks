from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("brace_range_expansion")
fn brace_range_expansion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65: return -1
    let declared = input[0]
    if declared < 1 or declared > 64 or length != c_size_t(declared + 1): return -1
    let n = Int(declared)
    var open = -1
    var close = -1
    for i in range(n):
        let byte = input[1+i]
        if byte < 32 or byte > 126: return -1
        if byte == 123:
            if open >= 0: return -1
            open = i
        elif byte == 125:
            if close >= 0: return -1
            close = i
    if open < 0 or close <= open or open+n-close-1 > 32: return -1
    var sep1 = -1
    var sep2 = -1
    var i = open+1
    while i+1 < close:
        if input[1+i] == 46 and input[2+i] == 46:
            if sep1 < 0: sep1 = i
            elif sep2 < 0: sep2 = i
            else: return -1
            i += 2
        else:
            i += 1
    if sep1 < 0: return -1

    let first_start = open+1
    let first_width = sep1-first_start
    var start = 0
    var start_letter = False
    var start_upper = False
    if first_width == 1 and ((input[1+first_start] >= 65 and input[1+first_start] <= 90) or
                             (input[1+first_start] >= 97 and input[1+first_start] <= 122)):
        start = Int(input[1+first_start])
        start_letter = True
        start_upper = start <= 90
    else:
        if first_width < 1 or first_width > 4: return -1
        for j in range(first_start, sep1):
            let byte = input[1+j]
            if byte < 48 or byte > 57: return -1
            start = start*10 + Int(byte-48)

    let second_start = sep1+2
    let second_end = if sep2 < 0 { close } else { sep2 }
    let second_width = second_end-second_start
    var finish = 0
    var finish_letter = False
    var finish_upper = False
    if second_width == 1 and ((input[1+second_start] >= 65 and input[1+second_start] <= 90) or
                              (input[1+second_start] >= 97 and input[1+second_start] <= 122)):
        finish = Int(input[1+second_start])
        finish_letter = True
        finish_upper = finish <= 90
    else:
        if second_width < 1 or second_width > 4: return -1
        for j in range(second_start, second_end):
            let byte = input[1+j]
            if byte < 48 or byte > 57: return -1
            finish = finish*10 + Int(byte-48)
    if start_letter != finish_letter or (start_letter and start_upper != finish_upper): return -1

    var step = if start <= finish { 1 } else { -1 }
    if sep2 >= 0:
        var step_start = sep2+2
        var sign = 1
        if step_start < close and (input[1+step_start] == 43 or input[1+step_start] == 45):
            if input[1+step_start] == 45: sign = -1
            step_start += 1
        if close-step_start < 1: return -1
        var magnitude = 0
        for j in range(step_start, close):
            let byte = input[1+j]
            if byte < 48 or byte > 57: return -1
            if magnitude < 10000:
                magnitude = magnitude*10 + Int(byte-48)
                if magnitude > 10000: magnitude = 10000
        if magnitude == 0: return -1
        step = sign*magnitude
    if (start < finish and step < 0) or (start > finish and step > 0): return -1
    var count = 1
    if start < finish: count = (finish-start)//step + 1
    elif start > finish: count = (start-finish)//(-step) + 1
    if count > 16: return -1
    var pad = 0
    if not start_letter and (input[1+first_start] == 48 or input[1+second_start] == 48):
        pad = max(first_width, second_width)

    var staged = InlineArray[UInt8, 591](fill=0)
    var out = 0
    var value = start
    let suffix_start = close+1
    for item in range(count):
        if item != 0:
            staged[out] = 0
            out += 1
        for j in range(open):
            staged[out] = UInt8(input[1+j])
            out += 1
        if start_letter:
            staged[out] = UInt8(value)
            out += 1
        else:
            var digits = InlineArray[Int, 4](fill=0)
            var used = 0
            var remaining = value
            while True:
                digits[used] = remaining % 10
                used += 1
                remaining //= 10
                if remaining == 0: break
            while used < pad:
                staged[out] = 48
                out += 1
            while used > 0:
                used -= 1
                staged[out] = UInt8(48+digits[used])
                out += 1
        for j in range(suffix_start, n):
            staged[out] = UInt8(input[1+j])
            out += 1
        value += step
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(out): return -2
    for j in range(out): output[j] = staged[j]
    return Int64(out)
