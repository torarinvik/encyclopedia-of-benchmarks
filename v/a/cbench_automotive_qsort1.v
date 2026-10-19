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

const max_points = 128
const max_coord = i64(1_000_000)

fn shortsort(mut ids []int, scores []f64, lo int, hi int) {
	mut end_index := hi
	for end_index > lo {
		mut maximum := lo
		for p in lo + 1 .. end_index + 1 { if scores[ids[p]] > scores[ids[maximum]] { maximum = p } }
		t := ids[maximum]; ids[maximum] = ids[end_index]; ids[end_index] = t
		end_index--
	}
}
fn sort_range(mut ids []int, scores []f64, lo int, hi int) {
	if hi <= lo { return }
	if hi - lo + 1 <= 8 { shortsort(mut ids, scores, lo, hi); return }
	mid := lo + (hi - lo + 1) / 2
	t := ids[mid]; ids[mid] = ids[lo]; ids[lo] = t
	mut loguy := lo
	mut higuy := hi + 1
	for {
		loguy++
		for loguy <= hi && scores[ids[loguy]] <= scores[ids[lo]] { loguy++ }
		higuy--
		for higuy > lo && scores[ids[higuy]] >= scores[ids[lo]] { higuy-- }
		if higuy < loguy { break }
		t2 := ids[loguy]; ids[loguy] = ids[higuy]; ids[higuy] = t2
	}
	t3 := ids[lo]; ids[lo] = ids[higuy]; ids[higuy] = t3
	if higuy > lo + 1 { sort_range(mut ids, scores, lo, higuy - 1) }
	if loguy < hi { sort_range(mut ids, scores, loguy, hi) }
}

@[export: 'cbench_automotive_qsort1']
pub fn cbench_automotive_qsort1(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 4 || length > 385 { return -1 }
	n_value := unsafe { values[0] }
	if n_value < 1 || n_value > max_points || length != usize(1 + 3*n_value) { return -1 }
	n := int(n_value)
	mut coords := [max_points][3]i32{}
	mut ids := [max_points]int{}
	mut scores := [max_points]f64{}
	mut radii := [max_points]i64{}
	for i in 0 .. n {
		mut sum := i64(0)
		for a in 0 .. 3 {
			v := unsafe { values[1+3*i+a] }
			if v < -max_coord || v > max_coord { return -1 }
			coords[i][a] = i32(v); sum += v*v
		}
		for j in 0 .. i { if radii[j] == sum { return -1 } }
		radii[i] = sum; ids[i] = i
		x := f64(coords[i][0]); y := f64(coords[i][1]); z := f64(coords[i][2])
		scores[i] = math.sqrt(x*x+y*y+z*z)
	}
	if unsafe { output == nil } || output_capacity < usize(12*n) { return -2 }
	sort_range(mut ids[..], scores[..], 0, n-1)
	mut staged := [max_points*12]u8{}
	for r in 0 .. n { for a in 0 .. 3 {
		bits := u32(coords[ids[r]][a])
		for b in 0 .. 4 { staged[12*r+4*a+b] = u8((bits >> (8*b)) & 255) }
	} }
	unsafe { for i in 0 .. 12*n { output[i] = staged[i] } }
	return i64(12*n)
}
