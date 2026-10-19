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

#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 128
#define MAX_OUTPUT (MAX_POINTS * 12)
#define MAX_COORD 1000000

static void shortsort(size_t *ids, const double *scores, size_t lo, size_t hi) {
    while (hi > lo) {
        size_t max = lo;
        for (size_t p = lo + 1; p <= hi; ++p)
            if (scores[ids[p]] > scores[ids[max]]) max = p;
        size_t t = ids[max]; ids[max] = ids[hi]; ids[hi] = t;
        --hi;
    }
}

static void qsortx(size_t *ids, const double *scores, size_t count) {
    size_t lostk[30], histk[30], stkptr = 0;
    size_t lo = 0, hi = count - 1;
    for (;;) {
        size_t size = hi - lo + 1;
        if (size <= 8) shortsort(ids, scores, lo, hi);
        else {
            size_t mid = lo + size / 2;
            size_t t = ids[mid]; ids[mid] = ids[lo]; ids[lo] = t;
            size_t loguy = lo, higuy = hi + 1;
            for (;;) {
                do { ++loguy; } while (loguy <= hi && scores[ids[loguy]] <= scores[ids[lo]]);
                do { --higuy; } while (higuy > lo && scores[ids[higuy]] >= scores[ids[lo]]);
                if (higuy < loguy) break;
                t = ids[loguy]; ids[loguy] = ids[higuy]; ids[higuy] = t;
            }
            t = ids[lo]; ids[lo] = ids[higuy]; ids[higuy] = t;
            if ((int64_t)higuy - 1 - (int64_t)lo >= (int64_t)hi - (int64_t)loguy) {
                if (lo + 1 < higuy) { lostk[stkptr] = lo; histk[stkptr++] = higuy - 1; }
                if (loguy < hi) { lo = loguy; continue; }
            } else {
                if (loguy < hi) { lostk[stkptr] = loguy; histk[stkptr++] = hi; }
                if (lo + 1 < higuy) { hi = higuy - 1; continue; }
            }
        }
        if (stkptr == 0) return;
        --stkptr; lo = lostk[stkptr]; hi = histk[stkptr];
    }
}

int64_t cbench_automotive_qsort1(const int64_t *values, size_t length,
                                  uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 4 || length > 1 + 3 * MAX_POINTS) return -1;
    int64_t n_value = values[0];
    if (n_value < 1 || n_value > MAX_POINTS || length != 1 + 3 * (size_t)n_value) return -1;
    size_t n = (size_t)n_value;
    int32_t coords[MAX_POINTS][3];
    size_t ids[MAX_POINTS];
    double scores[MAX_POINTS];
    int64_t radius2[MAX_POINTS];
    for (size_t i = 0; i < n; ++i) {
        int64_t sum = 0;
        for (size_t axis = 0; axis < 3; ++axis) {
            int64_t v = values[1 + 3 * i + axis];
            if (v < -MAX_COORD || v > MAX_COORD) return -1;
            coords[i][axis] = (int32_t)v;
            sum += v * v;
        }
        for (size_t j = 0; j < i; ++j) if (radius2[j] == sum) return -1;
        radius2[i] = sum;
        scores[i] = sqrt(pow((double)coords[i][0], 2.0) +
                         pow((double)coords[i][1], 2.0) +
                         pow((double)coords[i][2], 2.0));
        ids[i] = i;
    }
    if (output == NULL || output_capacity < 12 * n) return -2;
    qsortx(ids, scores, n);
    uint8_t staged[MAX_OUTPUT];
    for (size_t rank = 0; rank < n; ++rank) {
        size_t point = ids[rank];
        for (size_t axis = 0; axis < 3; ++axis) {
            uint32_t bits = (uint32_t)coords[point][axis];
            for (size_t byte = 0; byte < 4; ++byte)
                staged[12 * rank + 4 * axis + byte] = (uint8_t)(bits >> (8 * byte));
        }
    }
    for (size_t i = 0; i < 12 * n; ++i) output[i] = staged[i];
    return (int64_t)(12 * n);
}
