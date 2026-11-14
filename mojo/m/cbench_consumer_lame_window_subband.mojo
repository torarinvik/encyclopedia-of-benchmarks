# Copyright (c) 1999 Takehiro TOMINAGA
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.
#
# Independent bounded analysis filterbank draft; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_consumer_lame_window_subband")
fn cbench_consumer_lame_window_subband(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                      length: c_size_t,
                                      output: UnsafePointer[UInt8, MutAnyOrigin],
                                      capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 767: return -1
    for i in range(511):
        if input[i] < -32768 or input[i] > 32767: return -1
    for i in range(256):
        if input[511 + i] < -4500000 or input[511 + i] > 36000000: return -1
    if input[511] <= 25000000: return -1
    for i in range(16):
        if input[519 + 16 * i] <= 25000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 256: return -2

    var original = InlineArray[Float64, 256](fill=0.0)
    for i in range(256): original[i] = Float64(input[511 + i]) / 1000000000.0
    let maximum = original[248]
    var normalized = InlineArray[Float64, 239](fill=0.0)
    var scale = InlineArray[Float64, 31](fill=0.0)
    scale[15] = original[0] / maximum
    for i in range(7): normalized[i] = original[i + 1] / original[0]
    for group in range(15):
        let i = 14 - group
        let source = 8 + 16 * group
        let denominator = original[source]
        scale[i] = denominator / maximum
        scale[30 - i] = denominator / maximum
        for j in range(15): normalized[7 + 15 * group + j] = original[source + 1 + j] / denominator
    for j in range(7): normalized[232 + j] = original[249 + j] / maximum

    let s_offsets = InlineArray[Int, 15](334, 398, 462, 14, 78, 142, 206, 16, 80, 144, 208, 272, 336, 400, 464)
    let t_offsets = InlineArray[Int, 15](176, 112, 48, 496, 432, 368, 304, 494, 430, 366, 302, 238, 174, 110, 46)
    var inner = InlineArray[Float64, 31](fill=0.0)
    var center = Float64(input[255])
    for j in range(7):
        let left = input[223 - 32 * j]
        let right = input[287 + 32 * j]
        var pair = left - right
        if (j & 1) != 0: pair = left + right
        center += Float64(pair) * normalized[j]
    inner[15] = center
    for group in range(15):
        let i = 14 - group
        var s = Float64(input[270 - i])
        var t = Float64(input[240 + i])
        for j in range(15):
            var si = s_offsets[j] + i
            var ti = t_offsets[j] - i
            if j < 7:
                si = s_offsets[j] - i
                ti = t_offsets[j] + i
            let coefficient = normalized[7 + group * 15 + j]
            let sv = Float64(input[si]) * coefficient
            let tv = Float64(input[ti]) * coefficient
            if j >= 11: s -= sv
            else: s += sv
            if j >= 7 and j < 11: t -= tv
            else: t += tv
        inner[30 - i] = s
        inner[i] = t
    var edge = Float64(input[239])
    for j in range(7):
        var sample_index = 175 - 64 * j
        if j >= 3: sample_index = 303 + 64 * (j - 3)
        let term = Float64(input[sample_index]) * normalized[232 + j]
        if j >= 3: edge -= term
        else: edge += term

    var bands = InlineArray[Float64, 32](fill=0.0)
    for i in range(16):
        var even = edge
        var odd = inner[0] * (cos(Float64(2 * i + 1) * 3.14159265358979323846 / 64.0) * scale[0])
        for j in range(15):
            let k0 = 2 * j + 1
            let k1 = k0 + 1
            let angle0 = Float64((2 * i + 1) * (k0 + 1)) * 3.14159265358979323846 / 64.0
            let angle1 = Float64((2 * i + 1) * (k1 + 1)) * 3.14159265358979323846 / 64.0
            even += (cos(angle0) * scale[k0]) * inner[k0]
            odd += (cos(angle1) * scale[k1]) * inner[k1]
        bands[i] = even + odd
        bands[31 - i] = even - odd
    for i in range(32):
        let scaled = bands[i] * 1000.0
        var magnitude = scaled
        if magnitude < 0.0: magnitude = -magnitude
        var rounded = Int64(magnitude + 0.5)
        if scaled < 0.0: rounded = -rounded
        let bits = bitcast[UInt64](rounded)
        for j in range(8): output[8 * i + j] = UInt8((bits >> (8 * j)) & 255)
    return 256
