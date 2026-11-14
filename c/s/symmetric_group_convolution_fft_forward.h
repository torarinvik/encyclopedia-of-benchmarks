/* Uncompiled C subgroup-chain transform draft; not yet an ABI implementation. */
#ifndef SYMMETRIC_GROUP_CONVOLUTION_FFT_FORWARD_H
#define SYMMETRIC_GROUP_CONVOLUTION_FFT_FORWARD_H
#include "symmetric_group_convolution_fft_plan.h"

typedef struct { int64_t **items; size_t count; } sg_blocks;

static void sg_free_blocks(sg_blocks *blocks) {
    for (size_t i = 0; i < blocks->count; ++i) free(blocks->items[i]);
    free(blocks->items);
    blocks->items = NULL; blocks->count = 0;
}

static int sg_allocate_blocks(const sg_level *level, sg_blocks *blocks) {
    blocks->items = calloc(level->count, sizeof(*blocks->items));
    blocks->count = 0;
    if (!blocks->items) return SG_ALLOC;
    for (size_t i = 0; i < level->count; ++i) {
        size_t dimension = level->items[i].count;
        if (!dimension || dimension > SIZE_MAX / dimension / sizeof(int64_t)) {
            sg_free_blocks(blocks); return SG_INVARIANT;
        }
        blocks->items[i] = calloc(dimension*dimension, sizeof(int64_t));
        if (!blocks->items[i]) { sg_free_blocks(blocks); return SG_ALLOC; }
        ++blocks->count;
    }
    return 0;
}

static size_t sg_rank(const uint8_t *permutation, size_t n) {
    size_t rank = 0;
    for (size_t i = 0; i < n; ++i) {
        size_t less = 0;
        for (size_t j = i+1; j < n; ++j) less += permutation[j] < permutation[i];
        rank += less*sg_factorial[n-1-i];
    }
    return rank;
}

static int sg_next_permutation(uint8_t *permutation, size_t n) {
    if (n < 2) return 0;
    size_t pivot = n-1;
    while (pivot && permutation[pivot-1] >= permutation[pivot]) --pivot;
    if (!pivot) return 0;
    size_t other = n-1;
    while (permutation[other] <= permutation[pivot-1]) --other;
    uint8_t value = permutation[pivot-1]; permutation[pivot-1] = permutation[other];
    permutation[other] = value;
    for (size_t left = pivot, right = n-1; left < right; ++left, --right) {
        value = permutation[left]; permutation[left] = permutation[right]; permutation[right] = value;
    }
    return 1;
}

/* Apply a sparse generator, or its transpose, to a row-major square block. */
static int sg_apply_generator(const sg_rep *rep, size_t label, const int64_t *source,
                              int64_t *destination, int transpose) {
    size_t d = rep->count;
    memset(destination, 0, d*d*sizeof(*destination));
    for (size_t row = 0; row < d; ++row) {
        sg_column entry = rep->generators[label*d+row];
        if (entry.partner != SIZE_MAX && entry.partner >= d) return SG_INVARIANT;
        for (size_t col = 0; col < d; ++col) {
            if (transpose) {
                int64_t value = entry.diagonal*source[row*d+col]%SG_MOD;
                if (entry.partner != SIZE_MAX)
                    value = (value+entry.coefficient*source[entry.partner*d+col])%SG_MOD;
                destination[row*d+col] = value;
            } else {
                int64_t value = source[row*d+col];
                destination[row*d+col] = (destination[row*d+col]+entry.diagonal*value)%SG_MOD;
                if (entry.partner != SIZE_MAX) {
                    size_t index = entry.partner*d+col;
                    destination[index] = (destination[index]+entry.coefficient*value)%SG_MOD;
                }
            }
        }
    }
    return 0;
}

static int sg_forward(const sg_plan *plan, size_t n, const int64_t *input, sg_blocks *result) {
    const sg_level *level = &plan->levels[n];
    int status = sg_allocate_blocks(level, result);
    if (status) return status;
    if (n == 1) { result->items[0][0] = input[0]; return 0; }
    size_t sub_count = sg_factorial[n-1];
    int64_t *restricted = malloc(sub_count*sizeof(*restricted));
    if (!restricted) { sg_free_blocks(result); return SG_ALLOC; }
    for (size_t image = 0; image < n; ++image) {
        uint8_t h[9] = {0}, permutation[9] = {0};
        for (size_t i = 0; i+1 < n; ++i) h[i] = (uint8_t)i;
        size_t index = 0;
        do {
            for (size_t i = 0; i+1 < n; ++i) permutation[i] = h[i];
            permutation[n-1] = (uint8_t)(n-1);
            for (size_t i = 0; i < n; ++i) {
                if (permutation[i] == image) permutation[i] = (uint8_t)(n-1);
                else if (permutation[i] == n-1) permutation[i] = (uint8_t)image;
            }
            if (index >= sub_count) { status = SG_INVARIANT; goto failure; }
            restricted[index++] = input[sg_rank(permutation,n)];
        } while (sg_next_permutation(h,n-1));
        if (index != sub_count) { status = SG_INVARIANT; goto failure; }
        sg_blocks child = {0};
        status = sg_forward(plan,n-1,restricted,&child);
        if (status) goto failure;
        for (size_t shape = 0; shape < level->count; ++shape) {
            const sg_rep *rep = &level->items[shape];
            size_t d = rep->count, square = d*d;
            int64_t *block = calloc(square,sizeof(*block));
            int64_t *scratch = malloc(square*sizeof(*scratch));
            if (!block || !scratch) {
                free(block); free(scratch); sg_free_blocks(&child); status = SG_ALLOC; goto failure;
            }
            for (size_t k = 0; k < rep->restriction_count; ++k) {
                sg_embedding e = rep->restrictions[k];
                if (e.child >= child.count || e.offset > d || e.width > d-e.offset) {
                    free(block); free(scratch); sg_free_blocks(&child); status = SG_INVARIANT; goto failure;
                }
                for (size_t row = 0; row < e.width; ++row)
                    for (size_t col = 0; col < e.width; ++col)
                        block[(e.offset+row)*d+e.offset+col] = child.items[e.child][row*e.width+col];
            }
            for (size_t g = image; g+1 < n; ++g) {
                status = sg_apply_generator(rep,g,block,scratch,0);
                if (status) break;
                int64_t *swap = block; block = scratch; scratch = swap;
            }
            if (!status) for (size_t g = n-2; g-- > image;) {
                status = sg_apply_generator(rep,g,block,scratch,0);
                if (status) break;
                int64_t *swap = block; block = scratch; scratch = swap;
            }
            if (!status) for (size_t i = 0; i < square; ++i)
                result->items[shape][i] = (result->items[shape][i]+block[i])%SG_MOD;
            free(block); free(scratch);
            if (status) { sg_free_blocks(&child); goto failure; }
        }
        sg_free_blocks(&child);
    }
    free(restricted); return 0;
failure:
    free(restricted); sg_free_blocks(result); return status;
}
#endif
