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

package cbench_bzip2_mtf_rle

import "core:c"

MAX_BLOCK :: 32
MAX_TOKENS :: 33
MAX_INPUT :: 68

emit_zero_run :: proc "contextless" (tokens: [^]u8, used: ^int, count: int) {
	if count == 0 do return
	value := count - 1
	for {
		tokens[used^] = u8(value & 1)
		used^ += 1
		if value < 2 do break
		value = (value - 2) / 2
	}
}

@(export)
cbench_bzip2_mtf_rle :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
	capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	staged: [MAX_TOKENS]u8 = {}
	staged_count := 0

	if input[0] == 0 {
		if input[1] != 0 || input[2] < 1 || input[2] > MAX_BLOCK do return -1
		block_length := int(input[2])
		if length != c.size_t(3 + block_length) do return -1
		alphabet: [MAX_BLOCK]u8 = {}
		alphabet_length := 0
		for i := 0; i < block_length; i += 1 {
			value := input[3+i]
			if value < 0 || value > 255 do return -1
			at := 0
			for at < alphabet_length && alphabet[at] < u8(value) { at += 1 }
			if at < alphabet_length && alphabet[at] == u8(value) do continue
			for j := alphabet_length; j > at; j -= 1 { alphabet[j] = alphabet[j-1] }
			alphabet[at] = u8(value)
			alphabet_length += 1
		}
		order: [MAX_BLOCK]u8 = {}
		for i := 0; i < alphabet_length; i += 1 { order[i] = u8(i) }
		pending_zeros := 0
		for i := 0; i < block_length; i += 1 {
			value := u8(input[3+i])
			symbol := 0
			for alphabet[symbol] != value { symbol += 1 }
			rank := 0
			for int(order[rank]) != symbol { rank += 1 }
			if rank == 0 { pending_zeros += 1; continue }
			emit_zero_run(&staged[0], &staged_count, pending_zeros)
			pending_zeros = 0
			staged[staged_count] = u8(rank + 1)
			staged_count += 1
			moved := order[rank]
			for j := rank; j > 0; j -= 1 { order[j] = order[j-1] }
			order[0] = moved
		}
		emit_zero_run(&staged[0], &staged_count, pending_zeros)
		staged[staged_count] = u8(alphabet_length + 1)
		staged_count += 1
	} else if input[0] == 1 {
		if input[1] < 1 || input[1] > MAX_BLOCK || input[2] < 2 || input[2] > MAX_TOKENS do return -1
		alphabet_length := int(input[1])
		token_count := int(input[2])
		if length != c.size_t(3 + alphabet_length + token_count) do return -1
		order: [MAX_BLOCK]u8 = {}
		for i := 0; i < alphabet_length; i += 1 {
			symbol := input[3+i]
			if symbol < 0 || symbol > 255 || (i > 0 && input[2+i] >= symbol) do return -1
			order[i] = u8(symbol)
		}
		token_start := 3 + alphabet_length
		eob := i64(alphabet_length + 1)
		for i := 0; i < token_count; i += 1 {
			token := input[token_start+i]
			if token < 0 || token > eob || (i + 1 < token_count && token == eob) do return -1
		}
		if input[token_start+token_count-1] != eob do return -1
		index := 0
		for index + 1 < token_count {
			token := input[token_start+index]
			if token == 0 || token == 1 {
				run_count, weight := 0, 1
				for index + 1 < token_count {
					run_token := input[token_start+index]
					if run_token != 0 && run_token != 1 do break
					if weight > MAX_BLOCK do return -1
					add := int(run_token+1) * weight
					if run_count + add > MAX_BLOCK do return -1
					run_count += add
					weight *= 2
					index += 1
				}
				if staged_count + run_count > MAX_BLOCK do return -1
				for j := 0; j < run_count; j += 1 { staged[staged_count] = order[0]; staged_count += 1 }
				continue
			}
			if token < 2 || token >= eob do return -1
			rank := int(token - 1)
			if rank >= alphabet_length || staged_count >= MAX_BLOCK do return -1
			moved := order[rank]
			staged[staged_count] = moved
			staged_count += 1
			for j := rank; j > 0; j -= 1 { order[j] = order[j-1] }
			order[0] = moved
			index += 1
		}
		if staged_count == 0 do return -1
	} else {
		return -1
	}

	if output == nil || capacity < c.size_t(staged_count) do return -2
	for i := 0; i < staged_count; i += 1 { output[i] = staged[i] }
	return i64(staged_count)
}

