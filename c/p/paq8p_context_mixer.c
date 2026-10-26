/*
 * Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak,
 * Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson,
 * Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, KZ.
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version. It is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details: https://www.gnu.org/licenses/.
 */
#include <stddef.h>
#include <stdint.h>

static const int squash_table[33] = {1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094};

static int squash(int d) {
    if (d > 2047) return 4095;
    if (d < -2047) return 0;
    int w = d & 127;
    d = (d >> 7) + 16;
    return (squash_table[d] * (128 - w) + squash_table[d + 1] * w + 64) >> 7;
}

static void make_stretch(int *t) {
    int pi = 0;
    for (int x = -2047; x <= 2047; ++x) {
        int end = squash(x);
        for (int j = pi; j <= end; ++j) t[j] = x;
        pi = end + 1;
    }
    t[4095] = 2047;
}

static int dot8(const int *t, const int *w) {
    int sum = 0;
    for (int i = 0; i < 8; i += 2)
        sum += (t[i] * w[i] + t[i + 1] * w[i + 1]) >> 8;
    return sum;
}

static void train8(const int *t, int *w, int err) {
    for (int i = 0; i < 8; ++i) {
        int wt = w[i] + (((t[i] * err * 2 >> 16) + 1) >> 1);
        if (wt < -32768) wt = -32768;
        if (wt > 32767) wt = 32767;
        w[i] = wt;
    }
}

int64_t paq8p_context_mixer(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 12 || length > 177) return -1;
    int64_t count = input[0];
    if (count < 1 || count > 16 || length != 1 + (size_t)count * 11) return -1;
    int features[16][8], cx0[16], cx1[16], targets[16];
    size_t p = 1;
    for (int s = 0; s < (int)count; ++s) {
        if (input[p] < 0 || input[p] > 1 || input[p + 1] < 0 || input[p + 1] > 1 || input[p + 2] < 0 || input[p + 2] > 1) return -1;
        cx0[s] = (int)input[p++]; cx1[s] = (int)input[p++]; targets[s] = (int)input[p++];
        for (int j = 0; j < 8; ++j) {
            if (input[p] < -2047 || input[p] > 2047) return -1;
            features[s][j] = (int)input[p++];
        }
    }
    size_t needed = (size_t)count * 2;
    if (output == NULL || capacity < needed) return -2;

    int stretch[4096]; make_stretch(stretch);
    int outer_weights[4][8] = {{0}};
    int inner_weights[8];
    for (int i = 0; i < 8; ++i) inner_weights[i] = 32767;
    int previous_inner[8] = {0}, previous_inner_prediction = 2048, previous_target = 0;
    for (int s = 0; s < (int)count; ++s) {
        if (s > 0) {
            int err = ((previous_target << 12) - previous_inner_prediction) * 7;
            train8(previous_inner, inner_weights, err);
        }
        int contexts[2] = {cx0[s], 2 + cx1[s]};
        int model_predictions[2];
        for (int k = 0; k < 2; ++k)
            model_predictions[k] = squash(dot8(features[s], outer_weights[contexts[k]]) >> 5);
        int inner_inputs[8] = {stretch[model_predictions[0]], stretch[model_predictions[1]],0,0,0,0,0,0};
        int prediction = squash(dot8(inner_inputs, inner_weights) >> 8);
        output[s * 2] = (uint8_t)(prediction & 255);
        output[s * 2 + 1] = (uint8_t)((prediction >> 8) & 255);
        for (int k = 0; k < 2; ++k) {
            int err = ((targets[s] << 12) - model_predictions[k]) * 7;
            train8(features[s], outer_weights[contexts[k]], err);
        }
        for (int i = 0; i < 8; ++i) previous_inner[i] = inner_inputs[i];
        previous_inner_prediction = prediction;
        previous_target = targets[s];
    }
    return (int64_t)needed;
}
