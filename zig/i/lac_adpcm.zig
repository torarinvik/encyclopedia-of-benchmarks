/*
Copyright 1992 by Stichting Mathematisch Centrum, Amsterdam, The Netherlands.

                        All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the names of Stichting Mathematisch
Centrum or CWI not be used in advertising or publicity pertaining to
distribution of the software without specific, written prior permission.

STICHTING MATHEMATISCH CENTRUM DISCLAIMS ALL WARRANTIES WITH REGARD TO
THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS, IN NO EVENT SHALL STICHTING MATHEMATISCH CENTRUM BE LIABLE
FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

const INDEX_TABLE = [_]i32{-1,-1,-1,-1,2,4,6,8,-1,-1,-1,-1,2,4,6,8};
const STEP_TABLE = [_]i32{
    7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,
    88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,
    598,658,724,796,876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,2749,
    3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,8630,9493,10442,11487,
    12635,13899,15289,16818,18500,20350,22385,24623,27086,29794,32767,
};

fn clampIndex(value: i32) usize { return @intCast(@max(0, @min(88, value))); }
fn clampSample(value: i32) i32 { return @max(-32768, @min(32767, value)); }

fn encodeOne(sample: i32, predictor: *i32, index: *usize) u8 {
    var step = STEP_TABLE[index.*];
    var diff = sample - predictor.*;
    const sign: i32 = if (diff < 0) 8 else 0;
    if (sign != 0) diff = -diff;
    var code: i32 = 0;
    var change = step >> 3;
    if (diff >= step) { code = 4; diff -= step; change += step; }
    step >>= 1;
    if (diff >= step) { code |= 2; diff -= step; change += step; }
    step >>= 1;
    if (diff >= step) { code |= 1; change += step; }
    predictor.* = clampSample(predictor.* + (if (sign != 0) -change else change));
    code |= sign;
    index.* = clampIndex(@as(i32, @intCast(index.*)) + INDEX_TABLE[@intCast(code)]);
    return @intCast(code);
}

fn decodeOne(code: u8, predictor: *i32, index: *usize) i32 {
    const step = STEP_TABLE[index.*];
    index.* = clampIndex(@as(i32, @intCast(index.*)) + INDEX_TABLE[code]);
    const magnitude: i32 = code & 7;
    var change = step >> 3;
    if (magnitude & 4 != 0) change += step;
    if (magnitude & 2 != 0) change += step >> 1;
    if (magnitude & 1 != 0) change += step >> 2;
    predictor.* = clampSample(predictor.* + (if (code & 8 != 0) -change else change));
    return predictor.*;
}

export fn lac_adpcm(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 258) return -1;
    const values = input;
    const mode = values[0];
    const count = values[1];
    if (mode == 1) {
        if (count < 0 or count > 256 or length != @as(usize, @intCast(count)) + 2) return -1;
        for (0..@intCast(count)) |i| if (values[i + 2] < -32768 or values[i + 2] > 32767) return -1;
    } else if (mode == 2) {
        if (count < 0 or count > 128 or length != @as(usize, @intCast(count)) + 2) return -1;
        for (0..@intCast(count)) |i| if (values[i + 2] < 0 or values[i + 2] > 255) return -1;
    } else return -1;

    const n: usize = @intCast(count);
    const required = if (mode == 1) (n + 1) / 2 else n * 4;
    if (required == 0) return 0;
    if (output == null or capacity < required) return -2;
    var predictor: i32 = 0;
    var index: usize = 0;
    if (mode == 1) {
        for (0..n) |i| {
            const code = encodeOne(@intCast(values[i + 2]), &predictor, &index);
            if (i & 1 == 0) output[i / 2] = code << 4 else output[i / 2] |= code;
        }
    } else {
        for (0..n) |i| {
            const packed: u8 = @intCast(values[i + 2]);
            for (0..2) |half| {
                const code: u8 = if (half == 0) packed >> 4 else packed & 15;
                const bits: u16 = @truncate(decodeOne(code, &predictor, &index));
                const position = (i * 2 + half) * 2;
                output[position] = @truncate(bits);
                output[position + 1] = @truncate(bits >> 8);
            }
        }
    }
    return @intCast(required);
}
