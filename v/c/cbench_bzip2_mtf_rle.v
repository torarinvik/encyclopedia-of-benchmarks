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

const max_block = 32
const max_tokens = 33
const max_input = 68

fn emit_zero_run(mut tokens [33]u8, mut used int, count int) {
	if count == 0 { return }
	mut value := count - 1
	for {
		tokens[used] = if value & 1 != 0 { u8(1) } else { u8(0) }
		used++
		if value < 2 { break }
		value = (value - 2) / 2
	}
}

@[export: 'cbench_bzip2_mtf_rle']
pub fn cbench_bzip2_mtf_rle(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 3 || input_length > max_input { return -1 }
	mut staged := [33]u8{}
	mut staged_count := 0
	mode := unsafe { input[0] }
	if mode == 0 {
		if unsafe { input[1] != 0 || input[2] < 1 || input[2] > i64(max_block) } { return -1 }
		block_length := int(unsafe { input[2] })
		if input_length != usize(3 + block_length) { return -1 }
		mut alphabet := [32]u8{}
		mut alphabet_length := 0
		for i in 0 .. block_length {
			value := unsafe { input[3 + i] }
			if value < 0 || value > 255 { return -1 }
			mut at := 0
			for at < alphabet_length && alphabet[at] < u8(value) { at++ }
			if at < alphabet_length && alphabet[at] == u8(value) { continue }
			mut j := alphabet_length
			for j > at { alphabet[j] = alphabet[j - 1]; j-- }
			alphabet[at] = u8(value)
			alphabet_length++
		}
		mut order := [32]u8{}
		for i in 0 .. alphabet_length { order[i] = u8(i) }
		mut pending_zeros := 0
		for i in 0 .. block_length {
			value := u8(unsafe { input[3 + i] })
			mut symbol := 0
			for alphabet[symbol] != value { symbol++ }
			mut rank := 0
			for int(order[rank]) != symbol { rank++ }
			if rank == 0 { pending_zeros++; continue }
			emit_zero_run(mut staged, mut staged_count, pending_zeros)
			pending_zeros = 0
			staged[staged_count] = u8(rank + 1)
			staged_count++
			moved := order[rank]
			mut j := rank
			for j > 0 { order[j] = order[j - 1]; j-- }
			order[0] = moved
		}
		emit_zero_run(mut staged, mut staged_count, pending_zeros)
		staged[staged_count] = u8(alphabet_length + 1)
		staged_count++
	} else if mode == 1 {
		if unsafe { input[1] < 1 || input[1] > i64(max_block) || input[2] < 2 || input[2] > i64(max_tokens) } { return -1 }
		alphabet_length := int(unsafe { input[1] })
		token_count := int(unsafe { input[2] })
		if input_length != usize(3 + alphabet_length + token_count) { return -1 }
		mut order := [32]u8{}
		for i in 0 .. alphabet_length {
			symbol := unsafe { input[3 + i] }
			if symbol < 0 || symbol > 255 || (i > 0 && unsafe { input[2 + i] >= symbol }) { return -1 }
			order[i] = u8(symbol)
		}
		token_start := 3 + alphabet_length
		eob := i64(alphabet_length + 1)
		for i in 0 .. token_count {
			token := unsafe { input[token_start + i] }
			if token < 0 || token > eob || (i + 1 < token_count && token == eob) { return -1 }
		}
		if unsafe { input[token_start + token_count - 1] != eob } { return -1 }
		mut index := 0
		for index + 1 < token_count {
			token := unsafe { input[token_start + index] }
			if token == 0 || token == 1 {
				mut run_count := 0
				mut weight := 1
				for index + 1 < token_count {
					run_token := unsafe { input[token_start + index] }
					if run_token != 0 && run_token != 1 { break }
					if weight > max_block { return -1 }
					add := int(run_token + 1) * weight
					if run_count + add > max_block { return -1 }
					run_count += add
					weight *= 2
					index++
				}
				if staged_count + run_count > max_block { return -1 }
				for _ in 0 .. run_count { staged[staged_count] = order[0]; staged_count++ }
				continue
			}
			if token < 2 || token >= eob { return -1 }
			rank := int(token - 1)
			if rank >= alphabet_length || staged_count >= max_block { return -1 }
			moved := order[rank]
			staged[staged_count] = moved
			staged_count++
			mut j := rank
			for j > 0 { order[j] = order[j - 1]; j-- }
			order[0] = moved
			index++
		}
		if staged_count == 0 { return -1 }
	} else { return -1 }

	if unsafe { output == nil } || output_capacity < usize(staged_count) { return -2 }
	for i in 0 .. staged_count { unsafe { output[i] = staged[i] } }
	return i64(staged_count)
}
