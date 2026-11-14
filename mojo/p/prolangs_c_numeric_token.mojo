# Independent bounded numeric-token parser; see package README for provenance.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("prolangs_c_numeric_token")
fn prolangs_c_numeric_token(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 24: return -1
    let n = Int(length)
    var text = List[Int](capacity=n)
    for j in range(n):
        if input[j] < 32 or input[j] > 127: return -1
        text.append(Int(input[j]))
    var i = 0
    var integer = Int64(0)
    var had_integer = False
    while i < n and text[i] >= 48 and text[i] <= 57:
        had_integer = True
        let digit = Int64(text[i]-48)
        if integer > (Int64(2147483647)-digit)//10: return -1
        integer = integer*10+digit
        i += 1
    var token = Int64(256)
    var real = Float32(0.0)
    if i < n:
        token = 2001
        var has_dot = False
        var leading = 0
        var count = 0
        var fraction = 0
        if text[i] == 46:
            has_dot = True
            i += 1
            while i < n and text[i] == 48:
                leading += 1; i += 1
            if leading > 6: return -1
            while i < n and text[i] >= 48 and text[i] <= 57:
                if count == 6: return -1
                fraction = 10*fraction+text[i]-48
                count += 1; i += 1
            if leading+count > 6: return -1
        if count != 0:
            real = Float32(fraction)
            while real >= Float32(1.0): real /= Float32(10.0)
            for _ in range(leading): real /= Float32(10.0)
        real += Float32(integer)
        var has_exp = False
        if i < n and (text[i] == 101 or text[i] == 69):
            has_exp = True
            i += 1
            var sign = 1
            if i < n and (text[i] == 43 or text[i] == 45):
                if text[i] == 45: sign = -1
                i += 1
            if i == n or text[i] < 48 or text[i] > 57: return -1
            var exponent = 0
            while i < n and text[i] >= 48 and text[i] <= 57:
                exponent = exponent*10+text[i]-48
                i += 1
                if exponent > 6: return -1
            for _ in range(exponent):
                if sign > 0: real *= Float32(10.0)
                else: real /= Float32(10.0)
        if i != n or (not has_dot and not has_exp) or (not had_integer and not has_dot): return -1
    elif not had_integer: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 12: return -2
    let bits = real.bitcast[UInt32]()
    for j in range(4):
        output[j] = UInt8((token >> (8*j)) & 255)
        output[4+j] = UInt8((integer >> (8*j)) & 255)
        output[8+j] = UInt8((bits >> (8*j)) & 255)
    return 12
