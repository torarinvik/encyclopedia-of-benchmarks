// Altered, bounded clean-room port of a bzip2/libbzip2 1.0.4 coding stage.
//
// This program, "bzip2", the associated library "libbzip2", and all
// documentation, are copyright (C) 1996-2006 Julian R Seward. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. The origin of this software must not be misrepresented; you must not claim
//    that you wrote the original software. If you use this software in a
//    product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 3. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 4. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
// EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// Julian Seward, Cambridge, UK. jseward@bzip.org
// bzip2/libbzip2 version 1.0.4 of 20 December 2006

const MAX_BLOCK: usize = 32;
const MAX_TOKENS: usize = 33;
const MAX_INPUT: usize = 68;

fn emitZeroRun(tokens: *[MAX_TOKENS]u8, used: *usize, count: usize) void {
    if (count == 0) return;
    var value = count - 1;
    while (true) {
        tokens[used.*] = if ((value & 1) != 0) 1 else 0;
        used.* += 1;
        if (value < 2) break;
        value = (value - 2) / 2;
    }
}

pub export fn cbench_bzip2_mtf_rle(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 3 or input_length > MAX_INPUT) return -1;
    var staged = [_]u8{0} ** MAX_TOKENS;
    var staged_count: usize = 0;

    if (input[0] == 0) {
        if (input[1] != 0 or input[2] < 1 or input[2] > @as(i64, MAX_BLOCK) or input_length != 3 + @as(usize, @intCast(input[2]))) return -1;
        const block_length: usize = @intCast(input[2]);
        var alphabet = [_]u8{0} ** MAX_BLOCK;
        var alphabet_length: usize = 0;
        for (0..block_length) |i| {
            if (input[3 + i] < 0 or input[3 + i] > 255) return -1;
            const value: u8 = @intCast(input[3 + i]);
            var at: usize = 0;
            while (at < alphabet_length and alphabet[at] < value) : (at += 1) {}
            if (at < alphabet_length and alphabet[at] == value) continue;
            var j = alphabet_length;
            while (j > at) : (j -= 1) alphabet[j] = alphabet[j - 1];
            alphabet[at] = value;
            alphabet_length += 1;
        }
        var order = [_]u8{0} ** MAX_BLOCK;
        for (0..alphabet_length) |i| order[i] = @intCast(i);
        var pending_zeros: usize = 0;
        for (0..block_length) |i| {
            const value: u8 = @intCast(input[3 + i]);
            var symbol: usize = 0;
            while (alphabet[symbol] != value) : (symbol += 1) {}
            var rank: usize = 0;
            while (@as(usize, order[rank]) != symbol) : (rank += 1) {}
            if (rank == 0) { pending_zeros += 1; continue; }
            emitZeroRun(&staged, &staged_count, pending_zeros);
            pending_zeros = 0;
            staged[staged_count] = @intCast(rank + 1);
            staged_count += 1;
            const moved = order[rank];
            var j = rank;
            while (j > 0) : (j -= 1) order[j] = order[j - 1];
            order[0] = moved;
        }
        emitZeroRun(&staged, &staged_count, pending_zeros);
        staged[staged_count] = @intCast(alphabet_length + 1);
        staged_count += 1;
    } else if (input[0] == 1) {
        if (input[1] < 1 or input[1] > @as(i64, MAX_BLOCK) or input[2] < 2 or input[2] > @as(i64, MAX_TOKENS)) return -1;
        const alphabet_length: usize = @intCast(input[1]);
        const token_count: usize = @intCast(input[2]);
        if (input_length != 3 + alphabet_length + token_count) return -1;
        var order = [_]u8{0} ** MAX_BLOCK;
        for (0..alphabet_length) |i| {
            const symbol = input[3 + i];
            if (symbol < 0 or symbol > 255 or (i > 0 and input[2 + i] >= symbol)) return -1;
            order[i] = @intCast(symbol);
        }
        const token_start = 3 + alphabet_length;
        const eob: i64 = @intCast(alphabet_length + 1);
        for (0..token_count) |i| {
            const token = input[token_start + i];
            if (token < 0 or token > eob or (i + 1 < token_count and token == eob)) return -1;
        }
        if (input[token_start + token_count - 1] != eob) return -1;
        var index: usize = 0;
        while (index + 1 < token_count) {
            var token = input[token_start + index];
            if (token == 0 or token == 1) {
                var run_count: usize = 0;
                var weight: usize = 1;
                while (index + 1 < token_count) {
                    token = input[token_start + index];
                    if (token != 0 and token != 1) break;
                    if (weight > MAX_BLOCK) return -1;
                    const add = (@as(usize, @intCast(token)) + 1) * weight;
                    if (run_count + add > MAX_BLOCK) return -1;
                    run_count += add;
                    weight *= 2;
                    index += 1;
                }
                if (staged_count + run_count > MAX_BLOCK) return -1;
                for (0..run_count) |_| { staged[staged_count] = order[0]; staged_count += 1; }
                continue;
            }
            if (token < 2 or token >= eob) return -1;
            const rank: usize = @intCast(token - 1);
            if (rank >= alphabet_length or staged_count >= MAX_BLOCK) return -1;
            const moved = order[rank];
            staged[staged_count] = moved;
            staged_count += 1;
            var j = rank;
            while (j > 0) : (j -= 1) order[j] = order[j - 1];
            order[0] = moved;
            index += 1;
        }
        if (staged_count == 0) return -1;
    } else return -1;

    if (output == null or output_capacity < staged_count) return -2;
    for (0..staged_count) |i| output[i] = staged[i];
    return @intCast(staged_count);
}
