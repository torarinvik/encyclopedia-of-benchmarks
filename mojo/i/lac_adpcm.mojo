# Copyright 1992 by Stichting Mathematisch Centrum, Amsterdam, The Netherlands.
# All Rights Reserved
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appear in all copies and that
# both that copyright notice and this permission notice appear in
# supporting documentation, and that the names of Stichting Mathematisch
# Centrum or CWI not be used in advertising or publicity pertaining to
# distribution of the software without specific, written prior permission.
#
# STICHTING MATHEMATISCH CENTRUM DISCLAIMS ALL WARRANTIES WITH REGARD TO
# THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS, IN NO EVENT SHALL STICHTING MATHEMATISCH CENTRUM BE LIABLE
# FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
# OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn adpcm_index_delta(code: Int) -> Int:
    let magnitude = code & 7
    if magnitude < 4: return -1
    return 2 * (magnitude - 3)

@export("lac_adpcm")
fn lac_adpcm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1
    let mode = input[0]; let count_value = input[1]
    if mode == 1:
        if count_value < 0 or count_value > 256: return -1
    elif mode == 2:
        if count_value < 0 or count_value > 128: return -1
    else: return -1
    let count = Int(count_value)
    if length != c_size_t(count + 2): return -1
    for i in range(count):
        let x = input[i+2]
        if mode == 1 and (x < -32768 or x > 32767): return -1
        if mode == 2 and (x < 0 or x > 255): return -1
    let required = (count+1)//2 if mode == 1 else count*4
    if required == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var steps = InlineArray[Int, 89]()
    steps[0] = 7
    steps[1] = 8
    steps[2] = 9
    steps[3] = 10
    steps[4] = 11
    steps[5] = 12
    steps[6] = 13
    steps[7] = 14
    steps[8] = 16
    steps[9] = 17
    steps[10] = 19
    steps[11] = 21
    steps[12] = 23
    steps[13] = 25
    steps[14] = 28
    steps[15] = 31
    steps[16] = 34
    steps[17] = 37
    steps[18] = 41
    steps[19] = 45
    steps[20] = 50
    steps[21] = 55
    steps[22] = 60
    steps[23] = 66
    steps[24] = 73
    steps[25] = 80
    steps[26] = 88
    steps[27] = 97
    steps[28] = 107
    steps[29] = 118
    steps[30] = 130
    steps[31] = 143
    steps[32] = 157
    steps[33] = 173
    steps[34] = 190
    steps[35] = 209
    steps[36] = 230
    steps[37] = 253
    steps[38] = 279
    steps[39] = 307
    steps[40] = 337
    steps[41] = 371
    steps[42] = 408
    steps[43] = 449
    steps[44] = 494
    steps[45] = 544
    steps[46] = 598
    steps[47] = 658
    steps[48] = 724
    steps[49] = 796
    steps[50] = 876
    steps[51] = 963
    steps[52] = 1060
    steps[53] = 1166
    steps[54] = 1282
    steps[55] = 1411
    steps[56] = 1552
    steps[57] = 1707
    steps[58] = 1878
    steps[59] = 2066
    steps[60] = 2272
    steps[61] = 2499
    steps[62] = 2749
    steps[63] = 3024
    steps[64] = 3327
    steps[65] = 3660
    steps[66] = 4026
    steps[67] = 4428
    steps[68] = 4871
    steps[69] = 5358
    steps[70] = 5894
    steps[71] = 6484
    steps[72] = 7132
    steps[73] = 7845
    steps[74] = 8630
    steps[75] = 9493
    steps[76] = 10442
    steps[77] = 11487
    steps[78] = 12635
    steps[79] = 13899
    steps[80] = 15289
    steps[81] = 16818
    steps[82] = 18500
    steps[83] = 20350
    steps[84] = 22385
    steps[85] = 24623
    steps[86] = 27086
    steps[87] = 29794
    steps[88] = 32767
    var predictor = 0
    var step_index = 0
    if mode == 1:
        for i in range(count):
            let step = steps[step_index]
            var difference = Int(input[i+2]) - predictor
            var code = 0
            if difference < 0:
                code = 8
                difference = -difference
            var change = step >> 3
            if difference >= step:
                code |= 4; difference -= step; change += step
            if difference >= (step >> 1):
                code |= 2; difference -= step >> 1; change += step >> 1
            if difference >= (step >> 2):
                code |= 1; change += step >> 2
            predictor += -change if (code & 8) != 0 else change
            predictor = min(32767, max(-32768, predictor))
            step_index = min(88, max(0, step_index + adpcm_index_delta(code)))
            if (i & 1) == 0: output[i//2] = UInt8(code << 4)
            else: output[i//2] |= UInt8(code)
    else:
        for i in range(count):
            let packed = Int(input[i+2])
            for half in range(2):
                let code = packed >> 4 if half == 0 else packed & 15
                let step = steps[step_index]
                step_index = min(88, max(0, step_index + adpcm_index_delta(code)))
                var change = step >> 3
                if (code & 4) != 0: change += step
                if (code & 2) != 0: change += step >> 1
                if (code & 1) != 0: change += step >> 2
                predictor += -change if (code & 8) != 0 else change
                predictor = min(32767, max(-32768, predictor))
                let bits = UInt16(predictor & 65535)
                output[4*i+2*half] = UInt8(bits & 255)
                output[4*i+2*half+1] = UInt8(bits >> 8)
    return Int64(required)
