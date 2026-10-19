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

package cbench_automotive_qsort1

import "core:c"
import "core:math"

MAX_POINTS :: 128
MAX_COORD :: i64(1_000_000)

shortsort :: proc "contextless" (ids: [^]int, scores: [^]f64, lo, hi: int) {
	end_index := hi
	for end_index > lo {
		maximum := lo
		for p := lo+1; p <= end_index; p += 1 { if scores[ids[p]] > scores[ids[maximum]] { maximum = p } }
		t := ids[maximum]; ids[maximum] = ids[end_index]; ids[end_index] = t
		end_index -= 1
	}
}
sort_range :: proc "contextless" (ids: [^]int, scores: [^]f64, lo, hi: int) {
	if hi <= lo do return
	if hi-lo+1 <= 8 { shortsort(ids,scores,lo,hi); return }
	mid := lo+(hi-lo+1)/2
	t := ids[mid]; ids[mid] = ids[lo]; ids[lo] = t
	loguy := lo; higuy := hi+1
	for {
		loguy += 1
		for loguy <= hi && scores[ids[loguy]] <= scores[ids[lo]] { loguy += 1 }
		higuy -= 1
		for higuy > lo && scores[ids[higuy]] >= scores[ids[lo]] { higuy -= 1 }
		if higuy < loguy do break
		t2 := ids[loguy]; ids[loguy] = ids[higuy]; ids[higuy] = t2
	}
	t3 := ids[lo]; ids[lo] = ids[higuy]; ids[higuy] = t3
	if higuy > lo+1 { sort_range(ids,scores,lo,higuy-1) }
	if loguy < hi { sort_range(ids,scores,loguy,hi) }
}

@(export)
cbench_automotive_qsort1 :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > 385 do return -1
	n_value := values[0]
	if n_value < 1 || n_value > MAX_POINTS || length != c.size_t(1+3*n_value) do return -1
	n := int(n_value)
	var coords: [MAX_POINTS][3]i32
	var ids: [MAX_POINTS]int
	var scores: [MAX_POINTS]f64
	var radii: [MAX_POINTS]i64
	for i := 0; i < n; i += 1 {
		sum := i64(0)
		for axis := 0; axis < 3; axis += 1 {
			v := values[1+3*i+axis]
			if v < -MAX_COORD || v > MAX_COORD do return -1
			coords[i][axis] = i32(v); sum += v*v
		}
		for j := 0; j < i; j += 1 { if radii[j] == sum do return -1 }
		radii[i] = sum; ids[i] = i
		x := f64(coords[i][0]); y := f64(coords[i][1]); z := f64(coords[i][2])
		scores[i] = math.sqrt_f64(x*x+y*y+z*z)
	}
	if output == nil || output_capacity < c.size_t(12*n) do return -2
	sort_range(&ids[0],&scores[0],0,n-1)
	var staged: [MAX_POINTS*12]u8
	for r := 0; r < n; r += 1 { for axis := 0; axis < 3; axis += 1 {
		bits := u32(coords[ids[r]][axis])
		for byte := 0; byte < 4; byte += 1 { staged[12*r+4*axis+byte] = u8((bits >> (8*byte)) & 255) }
	} }
	for i := 0; i < 12*n; i += 1 { output[i] = staged[i] }
	return i64(12*n)
}
