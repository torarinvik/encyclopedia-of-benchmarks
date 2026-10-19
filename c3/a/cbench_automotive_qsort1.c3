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

module cbench_automotive_qsort1;

extern fn double sqrt(double value);

const long MAX_POINTS = 128;
const long MAX_COORD = 1000000;

fn void shortsort(usz* ids, double* score, usz lo, usz hi) {
    while (hi > lo) {
        usz maximum = lo;
        for (usz p = lo + 1; p <= hi; p++) if (score[ids[p]] > score[ids[maximum]]) maximum = p;
        usz t = ids[maximum]; ids[maximum] = ids[hi]; ids[hi] = t;
        hi--;
    }
}
fn void sort_range(usz* ids, double* score, usz lo, usz hi) {
    if (hi <= lo) return;
    if (hi - lo + 1 <= 8) { shortsort(ids, score, lo, hi); return; }
    usz mid = lo + (hi - lo + 1) / 2;
    usz t = ids[mid]; ids[mid] = ids[lo]; ids[lo] = t;
    usz loguy = lo, higuy = hi + 1;
    while (true) {
        do { loguy++; } while (loguy <= hi && score[ids[loguy]] <= score[ids[lo]]);
        do { higuy--; } while (higuy > lo && score[ids[higuy]] >= score[ids[lo]]);
        if (higuy < loguy) break;
        t = ids[loguy]; ids[loguy] = ids[higuy]; ids[higuy] = t;
    }
    t = ids[lo]; ids[lo] = ids[higuy]; ids[higuy] = t;
    if (higuy > lo + 1) sort_range(ids, score, lo, higuy - 1);
    if (loguy < hi) sort_range(ids, score, loguy, hi);
}

fn long cbench_automotive_qsort1(long* values, usz length, char* output,
                                  usz output_capacity) @export("cbench_automotive_qsort1") {
    if (values == null || length < 4 || length > 385) return -1;
    long n_value = values[0];
    if (n_value < 1 || n_value > MAX_POINTS || length != 1 + 3 * (usz)n_value) return -1;
    usz n = (usz)n_value;
    int coords[MAX_POINTS][3];
    usz ids[MAX_POINTS];
    double score[MAX_POINTS];
    long radius2[MAX_POINTS];
    for (usz i = 0; i < n; i++) {
        long sum = 0;
        for (usz a = 0; a < 3; a++) {
            long v = values[1 + 3*i + a];
            if (v < -MAX_COORD || v > MAX_COORD) return -1;
            coords[i][a] = (int)v; sum += v*v;
        }
        for (usz j = 0; j < i; j++) if (radius2[j] == sum) return -1;
        radius2[i] = sum; ids[i] = i;
        score[i] = sqrt((double)coords[i][0]*(double)coords[i][0] + (double)coords[i][1]*(double)coords[i][1] + (double)coords[i][2]*(double)coords[i][2]);
    }
    if (output == null || output_capacity < 12*n) return -2;
    sort_range(ids, score, 0, n-1);
    char staged[MAX_POINTS*12];
    for (usz r = 0; r < n; r++) for (usz a = 0; a < 3; a++) {
        uint bits = (uint)coords[ids[r]][a];
        for (usz b = 0; b < 4; b++) staged[12*r+4*a+b] = (char)((bits >> (8*b)) & 255);
    }
    for (usz i = 0; i < 12*n; i++) output[i] = staged[i];
    return (long)(12*n);
}
