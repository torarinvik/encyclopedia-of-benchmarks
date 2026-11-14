/* Uncompiled C inverse transform using the transposed subgroup recurrence. */
#ifndef SYMMETRIC_GROUP_CONVOLUTION_FFT_INVERSE_H
#define SYMMETRIC_GROUP_CONVOLUTION_FFT_INVERSE_H
#include "symmetric_group_convolution_fft_forward.h"

static int sg_invariant_diagonal(const sg_rep *rep, size_t n, int64_t *weights) {
    size_t d = rep->count;
    size_t *queue = malloc(d*sizeof(*queue));
    if (!queue) return SG_ALLOC;
    for (size_t i = 0; i < d; ++i) weights[i] = -1;
    for (size_t start = 0; start < d; ++start) {
        if (weights[start] != -1) continue;
        size_t head = 0, tail = 0;
        weights[start] = 1; queue[tail++] = start;
        while (head < tail) {
            size_t source = queue[head++];
            for (size_t label = 0; label+1 < n; ++label) {
                sg_column edge = rep->generators[label*d+source];
                if (edge.partner == SIZE_MAX) continue;
                if (edge.partner >= d) { free(queue); return SG_INVARIANT; }
                sg_column back = rep->generators[label*d+edge.partner];
                if (back.partner != source || !edge.coefficient || !back.coefficient) {
                    free(queue); return SG_INVARIANT;
                }
                int64_t candidate = weights[source]*back.coefficient%SG_MOD;
                candidate = candidate*sg_power(edge.coefficient,SG_MOD-2)%SG_MOD;
                if (weights[edge.partner] == -1) {
                    if (tail == d) { free(queue); return SG_INVARIANT; }
                    weights[edge.partner] = candidate; queue[tail++] = edge.partner;
                } else if (weights[edge.partner] != candidate) {
                    free(queue); return SG_INVARIANT;
                }
            }
        }
    }
    free(queue); return 0;
}

static int sg_transpose_forward(const sg_plan *plan, size_t n, const sg_blocks *gradients,
                                int64_t **result) {
    *result = NULL;
    int64_t *output = calloc(sg_factorial[n],sizeof(*output));
    if (!output) return SG_ALLOC;
    if (n == 1) { output[0] = gradients->items[0][0]; *result = output; return 0; }
    const sg_level *level = &plan->levels[n];
    int status = 0;
    for (size_t image = 0; image < n; ++image) {
        sg_blocks child = {0};
        status = sg_allocate_blocks(&plan->levels[n-1], &child);
        if (status) goto failure;
        for (size_t shape = 0; shape < level->count; ++shape) {
            const sg_rep *rep = &level->items[shape];
            size_t d = rep->count, square = d*d;
            int64_t *block = malloc(square*sizeof(*block));
            int64_t *scratch = malloc(square*sizeof(*scratch));
            if (!block || !scratch) {
                free(block); free(scratch); sg_free_blocks(&child); status = SG_ALLOC; goto failure;
            }
            memcpy(block,gradients->items[shape],square*sizeof(*block));
            for (size_t g = image; g+1 < n; ++g) {
                status = sg_apply_generator(rep,g,block,scratch,1);
                if (status) break;
                int64_t *swap = block; block = scratch; scratch = swap;
            }
            if (!status) for (size_t g = n-2; g-- > image;) {
                status = sg_apply_generator(rep,g,block,scratch,1);
                if (status) break;
                int64_t *swap = block; block = scratch; scratch = swap;
            }
            if (!status) for (size_t k = 0; k < rep->restriction_count; ++k) {
                sg_embedding e = rep->restrictions[k];
                if (e.child >= child.count || e.offset > d || e.width > d-e.offset) {
                    status = SG_INVARIANT; break;
                }
                for (size_t row = 0; row < e.width; ++row)
                    for (size_t col = 0; col < e.width; ++col) {
                        size_t index = row*e.width+col;
                        int64_t *target = &child.items[e.child][index];
                        *target = (*target+block[(e.offset+row)*d+e.offset+col])%SG_MOD;
                    }
            }
            free(block); free(scratch);
            if (status) { sg_free_blocks(&child); goto failure; }
        }
        int64_t *restricted = NULL;
        status = sg_transpose_forward(plan,n-1,&child,&restricted);
        sg_free_blocks(&child);
        if (status) goto failure;
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
            if (index >= sg_factorial[n-1]) { status = SG_INVARIANT; break; }
            output[sg_rank(permutation,n)] = restricted[index++];
        } while (sg_next_permutation(h,n-1));
        free(restricted);
        if (status || index != sg_factorial[n-1]) { status = SG_INVARIANT; goto failure; }
    }
    *result = output; return 0;
failure:
    free(output); return status;
}

static int sg_inverse(const sg_plan *plan, size_t n, const sg_blocks *blocks, int64_t **result) {
    const sg_level *level = &plan->levels[n];
    sg_blocks weighted = {0};
    int status = sg_allocate_blocks(level,&weighted);
    if (status) return status;
    int64_t inverse_order = sg_power((int64_t)sg_factorial[n],SG_MOD-2);
    for (size_t shape = 0; shape < level->count; ++shape) {
        const sg_rep *rep = &level->items[shape];
        size_t d = rep->count;
        int64_t *diagonal = malloc(d*sizeof(*diagonal));
        int64_t *inverse_diagonal = malloc(d*sizeof(*inverse_diagonal));
        if (!diagonal || !inverse_diagonal) {
            free(diagonal); free(inverse_diagonal); sg_free_blocks(&weighted); return SG_ALLOC;
        }
        status = sg_invariant_diagonal(rep,n,diagonal);
        if (status) { free(diagonal); free(inverse_diagonal); sg_free_blocks(&weighted); return status; }
        for (size_t i = 0; i < d; ++i) inverse_diagonal[i] = sg_power(diagonal[i],SG_MOD-2);
        for (size_t row = 0; row < d; ++row) for (size_t col = 0; col < d; ++col) {
            int64_t value = blocks->items[shape][row*d+col]*(int64_t)d%SG_MOD;
            value = value*inverse_order%SG_MOD;
            value = value*diagonal[row]%SG_MOD;
            weighted.items[shape][row*d+col] = value*inverse_diagonal[col]%SG_MOD;
        }
        free(diagonal); free(inverse_diagonal);
    }
    status = sg_transpose_forward(plan,n,&weighted,result);
    sg_free_blocks(&weighted); return status;
}
#endif
