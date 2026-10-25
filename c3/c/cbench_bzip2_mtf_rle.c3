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

module cbench_bzip2_mtf_rle;

const int MAX_BLOCK = 32;
const int MAX_TOKENS = 33;
const int MAX_INPUT = 68;

fn usz emit_zero_run(uchar* tokens, usz used, usz count) {
    if (count == 0) return used;
    usz value = count - 1;
    while (true) {
        tokens[used++] = (uchar)((value & 1) != 0 ? 1 : 0);
        if (value < 2) break;
        value = (value - 2) / 2;
    }
    return used;
}

fn long cbench_bzip2_mtf_rle(long* input, usz length, uchar* output, usz capacity)
        @export("cbench_bzip2_mtf_rle") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    uchar[MAX_TOKENS] staged;
    usz staged_count = 0;

    if (input[0] == 0) {
        if (input[1] != 0 || input[2] < 1 || input[2] > MAX_BLOCK) return -1;
        usz block_length = (usz)input[2];
        if (length != 3 + block_length) return -1;
        uchar[MAX_BLOCK] alphabet;
        usz alphabet_length = 0;
        for (usz i = 0; i < block_length; i++) {
            long value = input[3 + i];
            if (value < 0 || value > 255) return -1;
            usz at = 0;
            while (at < alphabet_length && alphabet[at] < (uchar)value) at++;
            if (at < alphabet_length && alphabet[at] == (uchar)value) continue;
            for (usz j = alphabet_length; j > at; j--) alphabet[j] = alphabet[j - 1];
            alphabet[at] = (uchar)value;
            alphabet_length++;
        }
        uchar[MAX_BLOCK] order;
        for (usz i = 0; i < alphabet_length; i++) order[i] = (uchar)i;
        usz pending_zeros = 0;
        for (usz i = 0; i < block_length; i++) {
            uchar value = (uchar)input[3 + i];
            usz symbol = 0;
            while (alphabet[symbol] != value) symbol++;
            usz rank = 0;
            while ((usz)order[rank] != symbol) rank++;
            if (rank == 0) { pending_zeros++; continue; }
            staged_count = emit_zero_run(&staged[0], staged_count, pending_zeros);
            pending_zeros = 0;
            staged[staged_count++] = (uchar)(rank + 1);
            uchar moved = order[rank];
            for (usz j = rank; j > 0; j--) order[j] = order[j - 1];
            order[0] = moved;
        }
        staged_count = emit_zero_run(&staged[0], staged_count, pending_zeros);
        staged[staged_count++] = (uchar)(alphabet_length + 1);
    } else if (input[0] == 1) {
        if (input[1] < 1 || input[1] > MAX_BLOCK || input[2] < 2 || input[2] > MAX_TOKENS) return -1;
        usz alphabet_length = (usz)input[1];
        usz token_count = (usz)input[2];
        if (length != 3 + alphabet_length + token_count) return -1;
        uchar[MAX_BLOCK] order;
        for (usz i = 0; i < alphabet_length; i++) {
            long symbol = input[3 + i];
            if (symbol < 0 || symbol > 255 || (i > 0 && input[2 + i] >= symbol)) return -1;
            order[i] = (uchar)symbol;
        }
        usz token_start = 3 + alphabet_length;
        long eob = (long)(alphabet_length + 1);
        for (usz i = 0; i < token_count; i++) {
            long token = input[token_start + i];
            if (token < 0 || token > eob || (i + 1 < token_count && token == eob)) return -1;
        }
        if (input[token_start + token_count - 1] != eob) return -1;
        usz index = 0;
        while (index + 1 < token_count) {
            long token = input[token_start + index];
            if (token == 0 || token == 1) {
                usz run_count = 0, weight = 1;
                while (index + 1 < token_count) {
                    token = input[token_start + index];
                    if (token != 0 && token != 1) break;
                    if (weight > MAX_BLOCK) return -1;
                    usz add = (usz)(token + 1) * weight;
                    if (run_count + add > MAX_BLOCK) return -1;
                    run_count += add;
                    weight *= 2;
                    index++;
                }
                if (staged_count + run_count > MAX_BLOCK) return -1;
                for (usz j = 0; j < run_count; j++) staged[staged_count++] = order[0];
                continue;
            }
            if (token < 2 || token >= eob) return -1;
            usz rank = (usz)(token - 1);
            if (rank >= alphabet_length || staged_count >= MAX_BLOCK) return -1;
            uchar moved = order[rank];
            staged[staged_count++] = moved;
            for (usz j = rank; j > 0; j--) order[j] = order[j - 1];
            order[0] = moved;
            index++;
        }
        if (staged_count == 0) return -1;
    } else return -1;

    if (output == null || capacity < staged_count) return -2;
    for (usz i = 0; i < staged_count; i++) output[i] = staged[i];
    return (long)staged_count;
}
