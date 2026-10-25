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

fn emit_zero_run(tokens: &mut [u8; MAX_TOKENS], used: &mut usize, count: usize) {
    if count == 0 { return; }
    let mut value = count - 1;
    loop {
        tokens[*used] = if value & 1 != 0 { 1 } else { 0 };
        *used += 1;
        if value < 2 { break; }
        value = (value - 2) / 2;
    }
}

#[no_mangle]
pub unsafe extern "C" fn cbench_bzip2_mtf_rle(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT { return -1; }
    let values = core::slice::from_raw_parts(input, input_length);
    let mut staged = [0u8; MAX_TOKENS];
    let mut staged_count = 0usize;

    if values[0] == 0 {
        if values[1] != 0 || values[2] < 1 || values[2] > MAX_BLOCK as i64 ||
            input_length != 3 + values[2] as usize { return -1; }
        let block_length = values[2] as usize;
        let mut alphabet = [0u8; MAX_BLOCK];
        let mut alphabet_length = 0usize;
        for i in 0..block_length {
            if !(0..=255).contains(&values[3 + i]) { return -1; }
            let value = values[3 + i] as u8;
            let mut at = 0usize;
            while at < alphabet_length && alphabet[at] < value { at += 1; }
            if at < alphabet_length && alphabet[at] == value { continue; }
            for j in (at..alphabet_length).rev() { alphabet[j + 1] = alphabet[j]; }
            alphabet[at] = value;
            alphabet_length += 1;
        }
        let mut order = [0u8; MAX_BLOCK];
        for i in 0..alphabet_length { order[i] = i as u8; }
        let mut pending_zeros = 0usize;
        for i in 0..block_length {
            let value = values[3 + i] as u8;
            let mut symbol = 0usize;
            while alphabet[symbol] != value { symbol += 1; }
            let mut rank = 0usize;
            while order[rank] as usize != symbol { rank += 1; }
            if rank == 0 { pending_zeros += 1; continue; }
            emit_zero_run(&mut staged, &mut staged_count, pending_zeros);
            pending_zeros = 0;
            staged[staged_count] = (rank + 1) as u8;
            staged_count += 1;
            let moved = order[rank];
            for j in (1..=rank).rev() { order[j] = order[j - 1]; }
            order[0] = moved;
        }
        emit_zero_run(&mut staged, &mut staged_count, pending_zeros);
        staged[staged_count] = (alphabet_length + 1) as u8;
        staged_count += 1;
    } else if values[0] == 1 {
        if values[1] < 1 || values[1] > MAX_BLOCK as i64 || values[2] < 2 || values[2] > MAX_TOKENS as i64 { return -1; }
        let alphabet_length = values[1] as usize;
        let token_count = values[2] as usize;
        if input_length != 3 + alphabet_length + token_count { return -1; }
        let mut order = [0u8; MAX_BLOCK];
        for i in 0..alphabet_length {
            let symbol = values[3 + i];
            if !(0..=255).contains(&symbol) || (i > 0 && values[2 + i] >= symbol) { return -1; }
            order[i] = symbol as u8;
        }
        let token_start = 3 + alphabet_length;
        let eob = (alphabet_length + 1) as i64;
        for i in 0..token_count {
            let token = values[token_start + i];
            if token < 0 || token > eob || (i + 1 < token_count && token == eob) { return -1; }
        }
        if values[token_start + token_count - 1] != eob { return -1; }

        let mut index = 0usize;
        while index + 1 < token_count {
            let mut token = values[token_start + index];
            if token == 0 || token == 1 {
                let mut run_count = 0usize;
                let mut weight = 1usize;
                while index + 1 < token_count {
                    token = values[token_start + index];
                    if token != 0 && token != 1 { break; }
                    if weight > MAX_BLOCK { return -1; }
                    let add = (token as usize + 1) * weight;
                    if run_count + add > MAX_BLOCK { return -1; }
                    run_count += add;
                    weight *= 2;
                    index += 1;
                }
                if staged_count + run_count > MAX_BLOCK { return -1; }
                for _ in 0..run_count { staged[staged_count] = order[0]; staged_count += 1; }
                continue;
            }
            if token < 2 || token >= eob { return -1; }
            let rank = (token - 1) as usize;
            if rank >= alphabet_length || staged_count >= MAX_BLOCK { return -1; }
            let moved = order[rank];
            staged[staged_count] = moved;
            staged_count += 1;
            for j in (1..=rank).rev() { order[j] = order[j - 1]; }
            order[0] = moved;
            index += 1;
        }
        if staged_count == 0 { return -1; }
    } else { return -1; }

    if output.is_null() || output_capacity < staged_count { return -2; }
    for i in 0..staged_count { output.add(i).write(staged[i]); }
    staged_count as i64
}
