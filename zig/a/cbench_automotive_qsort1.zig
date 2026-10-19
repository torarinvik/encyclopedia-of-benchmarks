// Modified derivative of cBench automotive_qsort1. Upstream directory notice, verbatim: “Matt wrote this using STL. It is GPL'ed.” The notice does not identify a GPL version. qsort.c copyright (C) 2002 Michael Ringgaard. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 3. Neither the name of the project nor the names of its contributors may be
//    used to endorse or promote products derived from this software without
//    specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

const MAX_POINTS: usize = 128;
const MAX_COORD: i64 = 1_000_000;

fn shortsort(ids: *[MAX_POINTS]usize, scores: *[MAX_POINTS]f64, lo: usize, hi: usize) void {
    var end_index = hi;
    while (end_index > lo) {
        var maximum = lo;
        var p = lo + 1;
        while (p <= end_index) : (p += 1) if (scores[ids[p]] > scores[ids[maximum]]) { maximum = p; };
        const t = ids[maximum]; ids[maximum] = ids[end_index]; ids[end_index] = t;
        end_index -= 1;
    }
}
fn sortRange(ids: *[MAX_POINTS]usize, scores: *[MAX_POINTS]f64, lo: usize, hi: usize) void {
    if (hi <= lo) return;
    if (hi - lo + 1 <= 8) { shortsort(ids, scores, lo, hi); return; }
    const mid = lo + (hi - lo + 1) / 2;
    var t = ids[mid]; ids[mid] = ids[lo]; ids[lo] = t;
    var loguy = lo; var higuy = hi + 1;
    while (true) {
        loguy += 1;
        while (loguy <= hi and scores[ids[loguy]] <= scores[ids[lo]]) : (loguy += 1) {}
        higuy -= 1;
        while (higuy > lo and scores[ids[higuy]] >= scores[ids[lo]]) : (higuy -= 1) {}
        if (higuy < loguy) break;
        t = ids[loguy]; ids[loguy] = ids[higuy]; ids[higuy] = t;
    }
    t = ids[lo]; ids[lo] = ids[higuy]; ids[higuy] = t;
    if (higuy > lo + 1) sortRange(ids, scores, lo, higuy - 1);
    if (loguy < hi) sortRange(ids, scores, loguy, hi);
}

export fn cbench_automotive_qsort1(values: [*c]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > 385) return -1;
    const n_value = values[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_POINTS)) or length != 1 + 3 * @as(usize, @intCast(n_value))) return -1;
    const n: usize = @intCast(n_value);
    var coords: [MAX_POINTS][3]i32 = undefined;
    var ids: [MAX_POINTS]usize = undefined;
    var scores: [MAX_POINTS]f64 = undefined;
    var radii: [MAX_POINTS]i64 = undefined;
    for (0..n) |i| {
        var sum: i64 = 0;
        for (0..3) |a| {
            const v = values[1 + 3 * i + a];
            if (v < -MAX_COORD or v > MAX_COORD) return -1;
            coords[i][a] = @intCast(v); sum += v * v;
        }
        for (0..i) |j| if (radii[j] == sum) return -1;
        radii[i] = sum; ids[i] = i;
        const x: f64 = @floatFromInt(coords[i][0]); const y: f64 = @floatFromInt(coords[i][1]); const z: f64 = @floatFromInt(coords[i][2]);
        scores[i] = @sqrt(x*x + y*y + z*z);
    }
    if (output_opt == null or output_capacity < 12*n) return -2;
    sortRange(&ids, &scores, 0, n-1);
    var staged: [MAX_POINTS * 12]u8 = undefined;
    for (0..n) |r| for (0..3) |a| {
        const bits: u32 = @bitCast(coords[ids[r]][a]);
        for (0..4) |b| staged[12*r+4*a+b] = @truncate(bits >> @intCast(8*b));
    };
    const output = output_opt.?;
    for (0..12*n) |i| output[i] = staged[i];
    return @intCast(12*n);
}
