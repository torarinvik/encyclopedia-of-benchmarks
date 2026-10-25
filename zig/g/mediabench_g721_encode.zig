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

const MAX_SAMPLES: usize = 16;
const POWER2 = [_]i64{1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384};
const QTAB = [_]i64{-124,80,178,246,300,349,400};
const DQLNTAB = [_]i64{-2048,4,135,213,273,323,373,425,425,373,323,273,213,135,4,-2048};
const WITAB = [_]i64{-12,18,41,64,112,198,355,1122,1122,355,198,112,64,41,18,-12};
const FITAB = [_]i64{0,0,0,512,512,512,1536,3584,3584,1536,512,512,512,0,0,0};

const State = struct {
    yl: i64 = 34816,
    yu: i64 = 544,
    dms: i64 = 0,
    dml: i64 = 0,
    ap: i64 = 0,
    a: [2]i64 = .{0,0},
    b: [6]i64 = .{0,0,0,0,0,0},
    pk: [2]i64 = .{0,0},
    dq: [6]i64 = .{32,32,32,32,32,32},
    sr: [2]i64 = .{32,32},
    td: i64 = 0,
};

fn wrap16(value: i64) i64 {
    const low = @as(u64, @bitCast(value)) & 0xffff;
    return if (low >= 0x8000) @as(i64, @intCast(low)) - 65536 else @as(i64, @intCast(low));
}
fn quantTable(value: i64, table: []const i64) i64 {
    var index: usize = 0;
    while (index < table.len and value >= table[index]) : (index += 1) {}
    return @intCast(index);
}
fn fmult(coefficient: i64, encoded: i64) i64 {
    const magnitude = if (coefficient > 0) coefficient else ((-coefficient) & 0x1fff);
    const exponent = quantTable(magnitude, POWER2[0..]) - 6;
    var mantissa: i64 = 32;
    if (magnitude != 0) mantissa = if (exponent >= 0) magnitude >> @intCast(exponent) else magnitude << @intCast(-exponent);
    const product_exponent = exponent + ((encoded >> 6) & 15) - 13;
    const product_mantissa = (mantissa * (encoded & 0o77) + 0x30) >> 4;
    const result = if (product_exponent >= 0)
        (product_mantissa << @intCast(product_exponent)) & 0x7fff
    else
        product_mantissa >> @intCast(-product_exponent);
    return if ((coefficient ^ encoded) < 0) -result else result;
}
fn predictorZero(s: *const State) i64 {
    var sum = fmult(s.b[0] >> 2, s.dq[0]);
    for (1..6) |i| sum += fmult(s.b[i] >> 2, s.dq[i]);
    return sum;
}
fn predictorPole(s: *const State) i64 { return fmult(s.a[1] >> 2, s.sr[1]) + fmult(s.a[0] >> 2, s.sr[0]); }
fn stepSize(s: *const State) i64 {
    if (s.ap >= 256) return s.yu;
    var y = s.yl >> 6;
    const difference = s.yu - y;
    const weight = s.ap >> 2;
    if (difference > 0) y += (difference * weight) >> 6 else if (difference < 0) y += (difference * weight + 0x3f) >> 6;
    return y;
}
fn quantize(difference: i64, step: i64) i64 {
    const magnitude = if (difference < 0) -difference else difference;
    const exponent = quantTable(magnitude >> 1, POWER2[0..]);
    const mantissa = ((magnitude << 7) >> @intCast(exponent)) & 0x7f;
    const normalized = ((exponent << 7) + mantissa) - (step >> 2);
    const index = quantTable(normalized, QTAB[0..]);
    return if (difference < 0) 15 - index else if (index == 0) 15 else index;
}
fn reconstruct(sign: i64, dqln: i64, step: i64) i64 {
    const dql = dqln + (step >> 2);
    if (dql < 0) return if (sign != 0) -32768 else 0;
    const exponent = (dql >> 7) & 15;
    const mantissa = 128 + (dql & 127);
    const value = (mantissa << 7) >> @intCast(14 - exponent);
    return if (sign != 0) value - 32768 else value;
}
fn abs64(value: i64) i64 { return if (value < 0) -value else value; }

fn update(step: i64, wi: i64, fi: i64, dq: i64, sr: i64, dqsez: i64, s: *State) void {
    const magnitude = dq & 0x7fff;
    const ylint = s.yl >> 15;
    const ylfrac = (s.yl >> 10) & 0x1f;
    const threshold1 = (32 + ylfrac) << @intCast(ylint);
    const threshold2 = if (ylint > 9) @as(i64, 31 << 10) else threshold1;
    const dqthr = (threshold2 + (threshold2 >> 1)) >> 1;
    const transition = s.td != 0 and magnitude > dqthr;
    s.yu = wrap16(step + ((wi - step) >> 5));
    if (s.yu < 544) s.yu = 544 else if (s.yu > 5120) s.yu = 5120;
    s.yl += s.yu + ((-s.yl) >> 6);
    if (transition) {
        s.a = .{0,0};
        s.b = .{0,0,0,0,0,0};
    } else {
        const pk0: i64 = if (dqsez < 0) 1 else 0;
        const pks1 = pk0 ^ s.pk[0];
        var a2p = s.a[1] - (s.a[1] >> 7);
        if (dqsez != 0) {
            const fa1 = if (pks1 != 0) s.a[0] else -s.a[0];
            if (fa1 < -8191) a2p -= 0x100 else if (fa1 > 8191) a2p += 0xff else a2p += fa1 >> 5;
            if ((pk0 ^ s.pk[1]) != 0) {
                if (a2p <= -12160) a2p = -12288 else if (a2p >= 12416) a2p = 12288 else a2p -= 0x80;
            } else if (a2p <= -12416) a2p = -12288 else if (a2p >= 12160) a2p = 12288 else a2p += 0x80;
        }
        a2p = wrap16(a2p);
        s.a[1] = a2p;
        s.a[0] = wrap16(s.a[0] - (s.a[0] >> 8));
        if (dqsez != 0) s.a[0] = wrap16(s.a[0] + (if (pks1 == 0) @as(i64, 192) else -192));
        const limit = 15360 - a2p;
        if (s.a[0] < -limit) s.a[0] = -limit else if (s.a[0] > limit) s.a[0] = limit;
        s.a[0] = wrap16(s.a[0]);
        for (0..6) |i| {
            s.b[i] = wrap16(s.b[i] - (s.b[i] >> 8));
            if ((dq & 0x7fff) != 0) s.b[i] = wrap16(s.b[i] + (if ((dq ^ s.dq[i]) >= 0) @as(i64, 128) else -128));
        }
    }
    var i: usize = 5;
    while (i > 0) : (i -= 1) s.dq[i] = s.dq[i - 1];
    if (magnitude == 0) s.dq[0] = if (dq >= 0) 0x20 else wrap16(0xfc20)
    else {
        const exponent = quantTable(magnitude, POWER2[0..]);
        const encoded = (exponent << 6) + ((magnitude << 6) >> @intCast(exponent));
        s.dq[0] = wrap16(if (dq >= 0) encoded else encoded - 0x400);
    }
    s.sr[1] = s.sr[0];
    if (sr == 0) s.sr[0] = 0x20
    else if (sr > 0) {
        const exponent = quantTable(sr, POWER2[0..]);
        s.sr[0] = wrap16((exponent << 6) + ((sr << 6) >> @intCast(exponent)));
    } else if (sr > -32768) {
        const absolute = -sr;
        const exponent = quantTable(absolute, POWER2[0..]);
        s.sr[0] = wrap16((exponent << 6) + ((absolute << 6) >> @intCast(exponent)) - 0x400);
    } else s.sr[0] = wrap16(0xfc20);
    s.pk[1] = s.pk[0];
    s.pk[0] = if (dqsez < 0) 1 else 0;
    s.td = if (transition) 0 else if (s.a[1] < -11776) 1 else 0;
    s.dms = wrap16(s.dms + ((fi - s.dms) >> 5));
    s.dml = wrap16(s.dml + (((fi << 2) - s.dml) >> 7));
    if (transition) s.ap = 256
    else if (step < 1536 or s.td == 1 or abs64((s.dms << 2) - s.dml) >= (s.dml >> 3)) s.ap = wrap16(s.ap + ((0x200 - s.ap) >> 4))
    else s.ap = wrap16(s.ap + ((-s.ap) >> 4));
}

fn ulawToLinear(input: i64) i64 {
    const value = (~input) & 0xff;
    var sample = ((value & 15) << 3) + 0x84;
    sample <<= @intCast((value & 0x70) >> 4);
    return if ((value & 0x80) != 0) 0x84 - sample else sample - 0x84;
}
fn encodeOne(input: i64, s: *State) i64 {
    const sample = ulawToLinear(input) >> 2;
    const sezi = wrap16(predictorZero(s));
    const sez = sezi >> 1;
    const se = wrap16((sezi + predictorPole(s)) >> 1);
    const difference = wrap16(sample - se);
    const step = wrap16(stepSize(s));
    const code = quantize(difference, step);
    const dq = wrap16(reconstruct(code & 8, DQLNTAB[@intCast(code)], step));
    const sr = wrap16(if (dq < 0) se - (dq & 0x3fff) else se + dq);
    const dqsez = wrap16(sr + sez - se);
    update(step, WITAB[@intCast(code)] << 5, FITAB[@intCast(code)], dq, sr, dqsez, s);
    return code;
}

export fn mediabench_g721_encode(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_SAMPLES + 1) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(MAX_SAMPLES))) return -1;
    const count: usize = @intCast(values[0]);
    if (input_length != count + 1) return -1;
    for (0..count) |i| if (values[i + 1] < 0 or values[i + 1] > 255) return -1;
    const required = (count + 1) / 2;
    if (required == 0) return 0;
    if (output == null or output_capacity < required) return -2;
    var state = State{};
    const bytes = output.?;
    for (0..count) |i| {
        const code: u8 = @intCast(encodeOne(values[i + 1], &state));
        if ((i & 1) == 0) bytes[i / 2] = code else bytes[i / 2] |= code << 4;
    }
    return @intCast(required);
}
