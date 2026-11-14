# This source code is a product of Sun Microsystems, Inc. and is provided
# for unrestricted use.  Users may copy or modify this source code without
# charge.
#
# SUN SOURCE CODE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING
# THE WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
#
# Sun source code is provided with no support and without any obligation on
# the part of Sun Microsystems, Inc. to assist in its use, correction,
# modification or enhancement.
#
# SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
# INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS SOFTWARE
# OR ANY PART THEREOF.
#
# In no event will Sun Microsystems, Inc. be liable for any lost revenue
# or profits or other special, indirect and consequential damages, even if
# Sun has been advised of the possibility of such damages.
#
# Sun Microsystems, Inc.
# 2550 Garcia Avenue
# Mountain View, California  94043

# This implementation has not yet been compiled or executed.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

struct G721State:
    var yl: Int64
    var yu: Int64
    var dms: Int64
    var dml: Int64
    var ap: Int64
    var a: InlineArray[Int64, 2]
    var b: InlineArray[Int64, 6]
    var pk: InlineArray[Int64, 2]
    var dq: InlineArray[Int64, 6]
    var sr: InlineArray[Int64, 2]
    var td: Int64

    fn __init__(out self):
        self.yl = 34816
        self.yu = 544
        self.dms = 0
        self.dml = 0
        self.ap = 0
        self.a = InlineArray[Int64, 2](fill=0)
        self.b = InlineArray[Int64, 6](fill=0)
        self.pk = InlineArray[Int64, 2](fill=0)
        self.dq = InlineArray[Int64, 6](fill=32)
        self.sr = InlineArray[Int64, 2](fill=32)
        self.td = 0

fn g721_wrap16(value: Int64) -> Int64:
    let low = value & 65535
    if low >= 32768:
        return low - 65536
    return low

fn g721_power_index(value: Int64) -> Int64:
    var boundary: Int64 = 1
    var index: Int64 = 0
    while index < 15 and value >= boundary:
        index += 1
        boundary <<= 1
    return index

fn g721_fmult(coefficient: Int64, encoded: Int64) -> Int64:
    var magnitude = coefficient
    if coefficient <= 0:
        magnitude = (-coefficient) & 8191
    let exponent = g721_power_index(magnitude) - 6
    var mantissa: Int64 = 32
    if magnitude != 0:
        if exponent >= 0:
            mantissa = magnitude >> exponent
        else:
            mantissa = magnitude << (-exponent)
    let product_exponent = exponent + ((encoded >> 6) & 15) - 13
    let product_mantissa = (mantissa * (encoded & 63) + 48) >> 4
    var product: Int64
    if product_exponent >= 0:
        product = (product_mantissa << product_exponent) & 32767
    else:
        product = product_mantissa >> (-product_exponent)
    if (coefficient ^ encoded) < 0:
        return -product
    return product

fn g721_predict_zero(state: G721State) -> Int64:
    var sum: Int64 = 0
    for i in range(6):
        sum += g721_fmult(state.b[i] >> 2, state.dq[i])
    return sum

fn g721_predict_pole(state: G721State) -> Int64:
    return g721_fmult(state.a[1] >> 2, state.sr[1]) + g721_fmult(state.a[0] >> 2, state.sr[0])

fn g721_step(state: G721State) -> Int64:
    if state.ap >= 256:
        return state.yu
    var step = state.yl >> 6
    let difference = state.yu - step
    let weight = state.ap >> 2
    if difference > 0:
        step += (difference * weight) >> 6
    elif difference < 0:
        step += (difference * weight + 63) >> 6
    return step

fn g721_quantize(difference: Int64, step: Int64) -> Int64:
    var magnitude = difference
    if magnitude < 0:
        magnitude = -magnitude
    let exponent = g721_power_index(magnitude >> 1)
    let mantissa = ((magnitude << 7) >> exponent) & 127
    let normalized = (exponent << 7) + mantissa - (step >> 2)
    var index: Int64 = 0
    if normalized >= -124: index += 1
    if normalized >= 80: index += 1
    if normalized >= 178: index += 1
    if normalized >= 246: index += 1
    if normalized >= 300: index += 1
    if normalized >= 349: index += 1
    if normalized >= 400: index += 1
    if difference < 0:
        return 15 - index
    if index == 0:
        return 15
    return index

fn g721_reconstruct(sign: Int64, logarithm: Int64, step: Int64) -> Int64:
    let adjusted = logarithm + (step >> 2)
    if adjusted < 0:
        if sign != 0: return -32768
        return 0
    let exponent = (adjusted >> 7) & 15
    let magnitude = ((128 + (adjusted & 127)) << 7) >> (14 - exponent)
    if sign != 0: return magnitude - 32768
    return magnitude

fn g721_ulaw(input: Int64) -> Int64:
    let value = (~input) & 255
    let magnitude = (((value & 15) << 3) + 132) << ((value & 112) >> 4)
    if value & 128 != 0: return 132 - magnitude
    return magnitude - 132

fn g721_update(step: Int64, wi: Int64, fi: Int64, dq: Int64, sr: Int64,
               dqsez: Int64, mut state: G721State):
    let magnitude = dq & 32767
    let integer = state.yl >> 15
    let fraction = (state.yl >> 10) & 31
    var threshold = (32 + fraction) << integer
    if integer > 9: threshold = 31 << 10
    let transition = state.td != 0 and magnitude > ((threshold + (threshold >> 1)) >> 1)

    state.yu = g721_wrap16(step + ((wi - step) >> 5))
    if state.yu < 544: state.yu = 544
    elif state.yu > 5120: state.yu = 5120
    state.yl += state.yu + ((-state.yl) >> 6)

    if transition:
        for i in range(2): state.a[i] = 0
        for i in range(6): state.b[i] = 0
    else:
        var polarity: Int64 = 0
        if dqsez < 0: polarity = 1
        let changed = polarity ^ state.pk[0]
        var a2 = state.a[1] - (state.a[1] >> 7)
        if dqsez != 0:
            var feedback = -state.a[0]
            if changed != 0: feedback = state.a[0]
            if feedback < -8191: a2 -= 256
            elif feedback > 8191: a2 += 255
            else: a2 += feedback >> 5
            if (polarity ^ state.pk[1]) != 0:
                if a2 <= -12160: a2 = -12288
                elif a2 >= 12416: a2 = 12288
                else: a2 -= 128
            else:
                if a2 <= -12416: a2 = -12288
                elif a2 >= 12160: a2 = 12288
                else: a2 += 128
        a2 = g721_wrap16(a2)
        state.a[1] = a2
        var a1 = g721_wrap16(state.a[0] - (state.a[0] >> 8))
        if dqsez != 0:
            if changed == 0: a1 = g721_wrap16(a1 + 192)
            else: a1 = g721_wrap16(a1 - 192)
        let limit = 15360 - a2
        if a1 < -limit: a1 = -limit
        elif a1 > limit: a1 = limit
        state.a[0] = g721_wrap16(a1)
        for i in range(6):
            var bi = g721_wrap16(state.b[i] - (state.b[i] >> 8))
            if magnitude != 0:
                if (dq ^ state.dq[i]) >= 0: bi = g721_wrap16(bi + 128)
                else: bi = g721_wrap16(bi - 128)
            state.b[i] = bi

    for offset in range(5):
        let i = 5 - offset
        state.dq[i] = state.dq[i - 1]
    if magnitude == 0:
        if dq >= 0: state.dq[0] = 32
        else: state.dq[0] = g721_wrap16(64544)
    else:
        let exponent = g721_power_index(magnitude)
        var encoded = (exponent << 6) + ((magnitude << 6) >> exponent)
        if dq < 0: encoded -= 1024
        state.dq[0] = g721_wrap16(encoded)

    state.sr[1] = state.sr[0]
    if sr == 0:
        state.sr[0] = 32
    elif sr > 0:
        let exponent = g721_power_index(sr)
        state.sr[0] = g721_wrap16((exponent << 6) + ((sr << 6) >> exponent))
    elif sr > -32768:
        let magnitude_sr = -sr
        let exponent = g721_power_index(magnitude_sr)
        state.sr[0] = g721_wrap16((exponent << 6) + ((magnitude_sr << 6) >> exponent) - 1024)
    else:
        state.sr[0] = g721_wrap16(64544)

    state.pk[1] = state.pk[0]
    state.pk[0] = 0
    if dqsez < 0: state.pk[0] = 1
    state.td = 0
    if not transition and state.a[1] < -11776: state.td = 1
    state.dms = g721_wrap16(state.dms + ((fi - state.dms) >> 5))
    state.dml = g721_wrap16(state.dml + (((fi << 2) - state.dml) >> 7))
    var difference = (state.dms << 2) - state.dml
    if difference < 0: difference = -difference
    if transition:
        state.ap = 256
    elif step < 1536 or state.td == 1 or difference >= (state.dml >> 3):
        state.ap = g721_wrap16(state.ap + ((512 - state.ap) >> 4))
    else:
        state.ap = g721_wrap16(state.ap + ((-state.ap) >> 4))

fn g721_encode_one(input: Int64, mut state: G721State) -> Int64:
    # The tables are symmetric around the two middle codewords.
    let sezi = g721_wrap16(g721_predict_zero(state))
    let sez = sezi >> 1
    let estimate = g721_wrap16((sezi + g721_predict_pole(state)) >> 1)
    let difference = g721_wrap16((g721_ulaw(input) >> 2) - estimate)
    let step = g721_wrap16(g721_step(state))
    let code = g721_quantize(difference, step)
    var index = code
    if index >= 8: index = 15 - index
    var logarithm: Int64 = -2048
    var wi: Int64 = -12
    var fi: Int64 = 0
    if index == 1:
        logarithm = 4; wi = 18
    elif index == 2:
        logarithm = 135; wi = 41
    elif index == 3:
        logarithm = 213; wi = 64; fi = 512
    elif index == 4:
        logarithm = 273; wi = 112; fi = 512
    elif index == 5:
        logarithm = 323; wi = 198; fi = 512
    elif index == 6:
        logarithm = 373; wi = 355; fi = 1536
    elif index == 7:
        logarithm = 425; wi = 1122; fi = 3584
    let dq = g721_wrap16(g721_reconstruct(code & 8, logarithm, step))
    var sr = estimate + dq
    if dq < 0: sr = estimate - (dq & 16383)
    sr = g721_wrap16(sr)
    let dqsez = g721_wrap16(sr + sez - estimate)
    g721_update(step, wi << 5, fi, dq, sr, dqsez, state)
    return code

@export("mediabench_g721_encode")
fn mediabench_g721_encode(input: UnsafePointer[Int64, ImmutAnyOrigin],
                          length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin],
                          capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 17:
        return -1
    let count_value = input[0]
    if count_value < 0 or count_value > 16:
        return -1
    let count = Int(count_value)
    if length != c_size_t(count + 1):
        return -1
    for i in range(count):
        if input[i + 1] < 0 or input[i + 1] > 255:
            return -1
    let required = (count + 1) // 2
    if required == 0:
        return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var state = G721State()
    for i in range(count):
        let code = UInt8(g721_encode_one(input[i + 1], state))
        if (i & 1) == 0:
            output[i // 2] = code
        else:
            output[i // 2] = output[i // 2] | (code << 4)
    return Int64(required)
