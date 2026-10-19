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

fn shortsort(ids: &mut [usize; MAX_POINTS], scores: &[f64; MAX_POINTS], lo: usize, hi: usize) {
    let mut end = hi;
    while end > lo {
        let mut maximum = lo;
        for p in lo + 1..=end { if scores[ids[p]] > scores[ids[maximum]] { maximum = p; } }
        ids.swap(maximum, end); end -= 1;
    }
}
fn sort_range(ids: &mut [usize; MAX_POINTS], scores: &[f64; MAX_POINTS], lo: usize, hi: usize) {
    if hi <= lo { return; }
    if hi - lo + 1 <= 8 { shortsort(ids, scores, lo, hi); return; }
    let mid = lo + (hi - lo + 1) / 2;
    ids.swap(mid, lo);
    let mut loguy = lo;
    let mut higuy = hi + 1;
    loop {
        loop { loguy += 1; if !(loguy <= hi && scores[ids[loguy]] <= scores[ids[lo]]) { break; } }
        loop { higuy -= 1; if !(higuy > lo && scores[ids[higuy]] >= scores[ids[lo]]) { break; } }
        if higuy < loguy { break; }
        ids.swap(loguy, higuy);
    }
    ids.swap(lo, higuy);
    if higuy > lo + 1 { sort_range(ids, scores, lo, higuy - 1); }
    if loguy < hi { sort_range(ids, scores, loguy, hi); }
}

#[no_mangle]
pub unsafe extern "C" fn cbench_automotive_qsort1(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 4 || length > 385 { return -1; }
    let n_value = *values;
    if n_value < 1 || n_value > MAX_POINTS as i64 || length != 1 + 3 * n_value as usize { return -1; }
    let n = n_value as usize;
    let mut coords = [[0i32; 3]; MAX_POINTS];
    let mut ids = [0usize; MAX_POINTS];
    let mut scores = [0.0f64; MAX_POINTS];
    let mut radii = [0i64; MAX_POINTS];
    for i in 0..n {
        let mut sum = 0i64;
        for a in 0..3 {
            let v = *values.add(1 + 3*i + a);
            if v < -MAX_COORD || v > MAX_COORD { return -1; }
            coords[i][a] = v as i32; sum += v*v;
        }
        if radii[..i].contains(&sum) { return -1; }
        radii[i] = sum; ids[i] = i;
        scores[i] = ((coords[i][0] as f64).powf(2.0) + (coords[i][1] as f64).powf(2.0) + (coords[i][2] as f64).powf(2.0)).sqrt();
    }
    if output.is_null() || output_capacity < 12*n { return -2; }
    sort_range(&mut ids, &scores, 0, n-1);
    let mut staged = [0u8; MAX_POINTS*12];
    for r in 0..n { for a in 0..3 {
        let bits = coords[ids[r]][a] as u32;
        for b in 0..4 { staged[12*r+4*a+b] = (bits >> (8*b)) as u8; }
    }}
    for i in 0..12*n { *output.add(i) = staged[i]; }
    (12*n) as i64
}
