// Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak, Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson, Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, KZ.
// This program is free software; redistribute and/or modify it under the GNU
// General Public License as published by the Free Software Foundation, either
// version 2 or (at your option) any later version. It is provided without any
// warranty, including merchantability or fitness for a particular purpose.
// See https://www.gnu.org/licenses/ for details.
const ST = [_]i32{1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094};

fn squash(d0: i32) i32 {
    if (d0 > 2047) return 4095;
    if (d0 < -2047) return 0;
    const w = d0 & 127;
    const d = (d0 >> 7) + 16;
    return (ST[@intCast(d)] * (128-w) + ST[@intCast(d+1)] * w + 64) >> 7;
}
fn makeStretch(t: *[4096]i32) void {
    var pi: i32 = 0;
    var x: i32 = -2047;
    while (x <= 2047) : (x += 1) {
        const end = squash(x);
        var j = pi;
        while (j <= end) : (j += 1) t[@intCast(j)] = x;
        pi = end + 1;
    }
    t[4095] = 2047;
}
fn dot8(t: [8]i32, w: [8]i32) i32 {
    var sum: i32 = 0;
    var i: usize = 0;
    while (i < 8) : (i += 2) sum += (t[i]*w[i] + t[i+1]*w[i+1]) >> 8;
    return sum;
}
fn train8(t: [8]i32, w: *[8]i32, err: i32) void {
    for (0..8) |i| {
        const value = w[i] + (((t[i]*err*2 >> 16) + 1) >> 1);
        w[i] = @max(-32768, @min(32767, value));
    }
}

export fn paq8p_context_mixer(input: [*]const i64, length: usize,
    output: [*]u8, capacity: usize) i64 {
    if (length < 12 or length > 177) return -1;
    const count = input[0];
    if (count < 1 or count > 16 or length != 1 + @as(usize, @intCast(count)) * 11) return -1;
    var features: [16][8]i32 = undefined;
    var c0: [16]usize = undefined; var c1: [16]usize = undefined; var targets: [16]i32 = undefined;
    var p: usize = 1;
    for (0..@intCast(count)) |s| {
        if (input[p] < 0 or input[p] > 1 or input[p+1] < 0 or input[p+1] > 1 or input[p+2] < 0 or input[p+2] > 1) return -1;
        c0[s] = @intCast(input[p]); c1[s] = @intCast(input[p+1]); targets[s] = @intCast(input[p+2]); p += 3;
        for (0..8) |j| { if (input[p] < -2047 or input[p] > 2047) return -1; features[s][j] = @intCast(input[p]); p += 1; }
    }
    const needed: usize = @as(usize, @intCast(count)) * 2;
    if (capacity < needed) return -2;
    var stretch: [4096]i32 = undefined; makeStretch(&stretch);
    var outer: [4][8]i32 = [_][8]i32{[_]i32{0} ** 8} ** 4;
    var inner: [8]i32 = @splat(32767);
    var previous_inner: [8]i32 = @splat(0);
    var previous_prediction: i32 = 2048; var previous_target: i32 = 0;
    for (0..@intCast(count)) |s| {
        if (s > 0) train8(previous_inner, &inner, ((previous_target << 12)-previous_prediction)*7);
        const contexts = [2]usize{c0[s], 2+c1[s]};
        var model: [2]i32 = undefined;
        for (0..2) |k| model[k] = squash(dot8(features[s], outer[contexts[k]]) >> 5);
        const x = [8]i32{stretch[@intCast(model[0])],stretch[@intCast(model[1])],0,0,0,0,0,0};
        const prediction = squash(dot8(x, inner) >> 8);
        output[s*2] = @intCast(prediction & 255); output[s*2+1] = @intCast((prediction >> 8) & 255);
        for (0..2) |k| train8(features[s], &outer[contexts[k]], ((targets[s] << 12)-model[k])*7);
        previous_inner=x; previous_prediction=prediction; previous_target=targets[s];
    }
    return @intCast(needed);
}
