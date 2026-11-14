# Independently written bounded BYTEmark arithmetic profile; see package LICENSE.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn nefa_sticky(mut value: UInt64, count: Int) -> UInt64:
    for _ in range(count):
        let lost = value & 1
        value = (value >> 1) | lost
    return value

@export("nbench_emulated_float_arithmetic")
fn nbench_emulated_float_arithmetic(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 14 or length > 105: return -1
    if input[0] < 1 or input[0] > 8 or length != c_size_t(1 + 13*input[0]): return -1
    let count = Int(input[0])
    var kinds = InlineArray[Int, 8](fill=0)
    var signs = InlineArray[Int, 8](fill=0)
    var exponents = InlineArray[Int, 8](fill=0)
    var mantissas = InlineArray[UInt64, 8](fill=0)
    let high_bit = UInt64(1) << 63
    for record in range(count):
        let base = 1 + 13*record
        let op = input[base]
        let sx = input[base+1]; let sy = input[base+7]
        let ex = input[base+2]; let ey = input[base+8]
        if op < 0 or op > 3 or sx < 0 or sx > 1 or sy < 0 or sy > 1: return -1
        if ex < -8 or ex > 8 or ey < -8 or ey > 8: return -1
        var x = UInt64(0); var y = UInt64(0)
        for word in range(4):
            let a = input[base+3+word]; let b = input[base+9+word]
            if a < 0 or a > 65535 or b < 0 or b > 65535: return -1
            x = (x << 16) | UInt64(a)
            y = (y << 16) | UInt64(b)
        if (x & high_bit) == 0 or (y & high_bit) == 0: return -1
        var kind = 2; var sign = Int(sx); var exponent = Int(ex)
        var result = UInt64(0)
        if op == 0 or op == 1:
            let difference = Int(ex-ey)
            if difference > 0: y = nefa_sticky(y, difference)
            elif difference < 0:
                x = nefa_sticky(x, -difference)
                exponent = Int(ey); sign = Int(sy ^ op)
            if (sx ^ sy ^ op) != 0:
                if x < y:
                    result = y-x; sign = Int(sy ^ op)
                else: result = x-y
                if result == 0: kind = 0; sign = 0
                else:
                    while (result & high_bit) == 0:
                        result <<= 1; exponent -= 1
            else:
                result = x+y
                if result < x:
                    exponent += 1
                    result = (result >> 1) | high_bit
        elif op == 2:
            sign = Int(sx ^ sy); exponent = Int(ex+ey)
            var high = UInt64(0); var low = UInt64(0); var multiplier = y
            for _ in range(64):
                var carry = UInt64(0)
                if (multiplier & 1) != 0:
                    let old = high
                    high += x
                    if high < old: carry = 1
                multiplier >>= 1
                let outgoing = high & 1
                high = (high >> 1) | (carry << 63)
                low = (low >> 1) | (outgoing << 63)
            while (high & high_bit) == 0:
                high = (high << 1) | (low >> 63)
                low <<= 1; exponent -= 1
            if low == 0: high |= 1
            result = high
        else:
            sign = Int(sx ^ sy); exponent = Int(ex-ey+128)
            var dividend = x; var remainder = UInt64(0)
            while (result & high_bit) == 0:
                let incoming = dividend >> 63
                dividend <<= 1
                let overflow = remainder >> 63
                remainder = (remainder << 1) | incoming
                var bit = UInt64(0)
                if overflow != 0 or remainder >= y:
                    remainder -= y; bit = 1
                result = (result << 1) | bit
                exponent -= 1
        if kind == 2:
            result &= ~UInt64(7)
            if exponent < -80 or exponent > 32 or (result & high_bit) == 0: return -1
        kinds[record] = kind; signs[record] = sign
        exponents[record] = exponent; mantissas[record] = result
    let bytes = 12*count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for record in range(count):
        let base = 12*record
        output[base] = UInt8(kinds[record]); output[base+1] = UInt8(signs[record])
        let expbits = exponents[record] & 65535
        output[base+2] = UInt8(expbits & 255); output[base+3] = UInt8(expbits >> 8)
        for word in range(4):
            let value = (mantissas[record] >> (48-16*word)) & 65535
            output[base+4+2*word] = UInt8(value & 255)
            output[base+5+2*word] = UInt8(value >> 8)
    return Int64(bytes)
