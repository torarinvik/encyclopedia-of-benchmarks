# SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("picojpeg")
fn picojpeg(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 139: return -1
    for i in range(139):
        if input[i] < 0 or input[i] > 255: return -1
    var header = List[Int64](capacity=7)
    header.append(255); header.append(216); header.append(255); header.append(219); header.append(0); header.append(67); header.append(0)
    for i in range(7):
        if input[i] != header[i]: return -1
    for i in range(64):
        let value = input[7+i]
        if value < 1 or (i >= 2 and value != 1): return -1
    var sof = List[Int64](capacity=13)
    sof.append(255); sof.append(192); sof.append(0); sof.append(11); sof.append(8); sof.append(0); sof.append(8); sof.append(0); sof.append(8); sof.append(1); sof.append(1); sof.append(17); sof.append(0)
    for i in range(13):
        if input[71+i] != sof[i]: return -1
    if input[84] != 255 or input[85] != 196 or input[86] != 0 or input[87] != 39 or input[88] != 0 or input[89] != 1 or input[90] != 0 or input[105] != 4 or input[106] != 16 or input[107] != 1 or input[108] != 1 or input[123] != 4 or input[124] != 0: return -1
    for i in range(91,105):
        if input[i] != 0: return -1
    for i in range(109,123):
        if input[i] != 0: return -1
    var sos = List[Int64](capacity=10)
    sos.append(255); sos.append(218); sos.append(0); sos.append(8); sos.append(1); sos.append(1); sos.append(0); sos.append(0); sos.append(63); sos.append(0)
    for i in range(10):
        if input[125+i] != sos[i]: return -1
    if input[137] != 255 or input[138] != 217: return -1
    let scan = (input[135] << 8) | input[136]
    if (scan & 32768) != 0 or (scan & 1024) != 0 or ((scan >> 4) & 3) != 2 or (scan & 15) != 15: return -1
    var dc = (scan >> 11) & 15
    var ac = (scan >> 6) & 15
    if dc < 8: dc -= 15
    if ac < 8: ac -= 15
    dc *= input[7]; ac *= input[8]
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 64: return -2
    var basis = List[Int64](capacity=8)
    basis.append(11363); basis.append(9633); basis.append(6436); basis.append(2260)
    basis.append(-2260); basis.append(-6436); basis.append(-9633); basis.append(-11363)
    for y in range(8):
        for x in range(8):
            let numerator = 128*65536+dc*8192+ac*basis[x]+32768
            var pixel = Int64(0)
            if numerator >= 0: pixel = numerator//65536
            else: pixel = -((-numerator+65535)//65536)
            if pixel < 0: pixel = 0
            if pixel > 255: pixel = 255
            output[8*y+x] = UInt8(pixel)
    return 64
