/*
 * This source code is a product of Sun Microsystems, Inc. and is provided
 * for unrestricted use.  Users may copy or modify this source code without
 * charge.
 *
 * SUN SOURCE CODE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING
 * THE WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 *
 * Sun source code is provided with no support and without any obligation on
 * the part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 *
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS SOFTWARE
 * OR ANY PART THEREOF.
 *
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even if
 * Sun has been advised of the possibility of such damages.
 *
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

package mediabench_g721_encode

import "core:c"

MAX_SAMPLES :: 16
POWER2 :: [15]i64{1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384}
QTAB :: [7]i64{-124,80,178,246,300,349,400}
DQLNTAB :: [16]i64{-2048,4,135,213,273,323,373,425,425,373,323,273,213,135,4,-2048}
WITAB :: [16]i64{-12,18,41,64,112,198,355,1122,1122,355,198,112,64,41,18,-12}
FITAB :: [16]i64{0,0,0,512,512,512,1536,3584,3584,1536,512,512,512,0,0,0}

State :: struct {
    yl, yu, dms, dml, ap: i64,
    a: [2]i64,
    b: [6]i64,
    pk: [2]i64,
    dq: [6]i64,
    sr: [2]i64,
    td: i64,
}

wrap16 :: proc "contextless" (value: i64) -> i64 {
    low := transmute(u64)value & 0xffff
    if low >= 0x8000 do return i64(low) - 65536
    return i64(low)
}
qtable :: proc "contextless" (value: i64, table: []i64) -> i64 {
    count: i64 = 0
    for item in table { if value < item do break; count += 1; }
    return count
}
fmult :: proc "contextless" (coefficient, encoded: i64) -> i64 {
    magnitude := coefficient
    if magnitude <= 0 do magnitude = (-coefficient) & 0x1fff
    exponent := qtable(magnitude, POWER2[:]) - 6
    mantissa := i64(32)
    if magnitude != 0 { if exponent >= 0 { mantissa = magnitude >> u64(exponent) } else { mantissa = magnitude << u64(-exponent) } }
    product_exponent := exponent + ((encoded >> 6) & 15) - 13
    product_mantissa := (mantissa * (encoded & 0o77) + 0x30) >> 4
    result := i64(0)
    if product_exponent >= 0 do result = (product_mantissa << u64(product_exponent)) & 0x7fff else result = product_mantissa >> u64(-product_exponent)
    if (coefficient ^ encoded) < 0 do return -result
    return result
}
predictor_zero :: proc "contextless" (s: ^State) -> i64 {
    sum := fmult(s.b[0] >> 2, s.dq[0])
    for i in 1..<6 { sum += fmult(s.b[i] >> 2, s.dq[i]) }
    return sum
}
predictor_pole :: proc "contextless" (s: ^State) -> i64 { return fmult(s.a[1] >> 2, s.sr[1]) + fmult(s.a[0] >> 2, s.sr[0]) }
step_size :: proc "contextless" (s: ^State) -> i64 {
    if s.ap >= 256 do return s.yu
    y := s.yl >> 6
    difference := s.yu - y
    weight := s.ap >> 2
    if difference > 0 { y += (difference * weight) >> 6 } else if difference < 0 { y += (difference * weight + 0x3f) >> 6 }
    return y
}
quantize :: proc "contextless" (difference, step: i64) -> i64 {
    magnitude := difference
    if magnitude < 0 do magnitude = -magnitude
    exponent := qtable(magnitude >> 1, POWER2[:])
    mantissa := ((magnitude << 7) >> u64(exponent)) & 0x7f
    normalized := ((exponent << 7) + mantissa) - (step >> 2)
    index := qtable(normalized, QTAB[:])
    if difference < 0 do return 15 - index
    if index == 0 do return 15
    return index
}
reconstruct :: proc "contextless" (sign, dqln, step: i64) -> i64 {
    dql := dqln + (step >> 2)
    if dql < 0 { if sign != 0 do return -32768; return 0 }
    exponent := (dql >> 7) & 15
    mantissa := 128 + (dql & 127)
    value := (mantissa << 7) >> u64(14 - exponent)
    if sign != 0 do return value - 32768
    return value
}
abs64 :: proc "contextless" (value: i64) -> i64 { if value < 0 do return -value; return value }

update :: proc "contextless" (step, wi, fi, dq, sr, dqsez: i64, s: ^State) {
    magnitude := dq & 0x7fff
    ylint := s.yl >> 15
    ylfrac := (s.yl >> 10) & 0x1f
    threshold1 := (32 + ylfrac) << u64(ylint)
    threshold2 := threshold1
    if ylint > 9 do threshold2 = 31 << 10
    dqthr := (threshold2 + (threshold2 >> 1)) >> 1
    transition := s.td != 0 && magnitude > dqthr
    s.yu = wrap16(step + ((wi - step) >> 5))
    if s.yu < 544 do s.yu = 544 else if s.yu > 5120 do s.yu = 5120
    s.yl += s.yu + ((-s.yl) >> 6)
    if transition {
        s.a[0] = 0; s.a[1] = 0
        for i in 0..<6 { s.b[i] = 0 }
    } else {
        pk0 := i64(0); if dqsez < 0 do pk0 = 1
        pks1 := pk0 ^ s.pk[0]
        a2p := s.a[1] - (s.a[1] >> 7)
        if dqsez != 0 {
            fa1 := s.a[0]; if pks1 == 0 do fa1 = -fa1
            if fa1 < -8191 do a2p -= 0x100 else if fa1 > 8191 do a2p += 0xff else a2p += fa1 >> 5
            if (pk0 ^ s.pk[1]) != 0 {
                if a2p <= -12160 do a2p = -12288 else if a2p >= 12416 do a2p = 12288 else a2p -= 0x80
            } else {
                if a2p <= -12416 do a2p = -12288 else if a2p >= 12160 do a2p = 12288 else a2p += 0x80
            }
        }
        a2p = wrap16(a2p); s.a[1] = a2p
        s.a[0] = wrap16(s.a[0] - (s.a[0] >> 8))
        if dqsez != 0 { if pks1 == 0 do s.a[0] = wrap16(s.a[0] + 192) else s.a[0] = wrap16(s.a[0] - 192) }
        limit := 15360 - a2p
        if s.a[0] < -limit do s.a[0] = -limit else if s.a[0] > limit do s.a[0] = limit
        s.a[0] = wrap16(s.a[0])
        for i in 0..<6 {
            s.b[i] = wrap16(s.b[i] - (s.b[i] >> 8))
            if (dq & 0x7fff) != 0 { if (dq ^ s.dq[i]) >= 0 do s.b[i] = wrap16(s.b[i] + 128) else s.b[i] = wrap16(s.b[i] - 128) }
        }
    }
    for i := 5; i > 0; i -= 1 { s.dq[i] = s.dq[i - 1] }
    if magnitude == 0 { if dq >= 0 do s.dq[0] = 0x20 else s.dq[0] = wrap16(0xfc20) }
    else { exponent := qtable(magnitude, POWER2[:]); encoded := (exponent << 6) + ((magnitude << 6) >> u64(exponent)); if dq >= 0 do s.dq[0] = wrap16(encoded) else s.dq[0] = wrap16(encoded - 0x400) }
    s.sr[1] = s.sr[0]
    if sr == 0 do s.sr[0] = 0x20
    else if sr > 0 { exponent := qtable(sr, POWER2[:]); s.sr[0] = wrap16((exponent << 6) + ((sr << 6) >> u64(exponent))) }
    else if sr > -32768 { absolute := -sr; exponent := qtable(absolute, POWER2[:]); s.sr[0] = wrap16((exponent << 6) + ((absolute << 6) >> u64(exponent)) - 0x400) }
    else s.sr[0] = wrap16(0xfc20)
    s.pk[1] = s.pk[0]; if dqsez < 0 do s.pk[0] = 1 else s.pk[0] = 0
    if transition do s.td = 0 else if s.a[1] < -11776 do s.td = 1 else s.td = 0
    s.dms = wrap16(s.dms + ((fi - s.dms) >> 5)); s.dml = wrap16(s.dml + (((fi << 2) - s.dml) >> 7))
    if transition do s.ap = 256 else if step < 1536 || s.td == 1 || abs64((s.dms << 2) - s.dml) >= (s.dml >> 3) do s.ap = wrap16(s.ap + ((0x200 - s.ap) >> 4)) else s.ap = wrap16(s.ap + ((-s.ap) >> 4))
}

init_state :: proc "contextless" () -> State {
    s: State; s.yl = 34816; s.yu = 544; s.dms = 0; s.dml = 0; s.ap = 0; s.td = 0
    for i in 0..<2 { s.a[i] = 0; s.pk[i] = 0; s.sr[i] = 32 }
    for i in 0..<6 { s.b[i] = 0; s.dq[i] = 32 }
    return s
}
ulaw_to_linear :: proc "contextless" (input: i64) -> i64 { value := (~input) & 0xff; t := ((value & 15) << 3) + 0x84; t <<= u64((value & 0x70) >> 4); if (value & 0x80) != 0 do return 0x84 - t; return t - 0x84 }
encode_one :: proc "contextless" (input: i64, s: ^State) -> i64 {
    sample := ulaw_to_linear(input) >> 2; sezi := wrap16(predictor_zero(s)); sez := sezi >> 1
    se := wrap16((sezi + predictor_pole(s)) >> 1); difference := wrap16(sample - se); step := wrap16(step_size(s))
    code := quantize(difference, step); dq := wrap16(reconstruct(code & 8, DQLNTAB[code], step))
    sr := wrap16(se + dq); if dq < 0 do sr = wrap16(se - (dq & 0x3fff))
    dqsez := wrap16(sr + sez - se); update(step, WITAB[code] << 5, FITAB[code], dq, sr, dqsez, s)
    return code
}

@(export)
mediabench_g721_encode :: proc "c" (input: [^]i64, input_length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 1 || input_length > MAX_SAMPLES + 1 do return -1
    count_value := input[0]; if count_value < 0 || count_value > MAX_SAMPLES do return -1
    count := int(count_value); if input_length != c.size_t(count + 1) do return -1
    for i in 0..<count { if input[i + 1] < 0 || input[i + 1] > 255 do return -1 }
    required := c.size_t((count + 1) / 2); if required == 0 do return 0
    if output == nil || output_capacity < required do return -2
    state := init_state()
    for i in 0..<count { code := u8(encode_one(input[i + 1], &state)); if i & 1 == 0 do output[i / 2] = code else output[i / 2] |= code << 4 }
    return i64(required)
}
