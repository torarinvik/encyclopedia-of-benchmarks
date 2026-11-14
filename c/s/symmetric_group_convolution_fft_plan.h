/* Uncompiled C research draft: representation plan for S_1 through S_9.
 * This file is not a complete convolution implementation. */
#ifndef SYMMETRIC_GROUP_CONVOLUTION_FFT_PLAN_H
#define SYMMETRIC_GROUP_CONVOLUTION_FFT_PLAN_H
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

enum { SG_ALLOC = -3, SG_INVARIANT = -4 };
#define SG_MOD INT64_C(998244353)
static const size_t sg_factorial[10] = {1,1,2,6,24,120,720,5040,40320,362880};

typedef struct { uint8_t cell[9]; } sg_tableau;
typedef struct { size_t partner; int64_t diagonal, coefficient; } sg_column;
typedef struct { size_t child, offset, width; } sg_embedding;
typedef struct {
    uint8_t shape[9];
    sg_tableau *basis;
    size_t count, capacity;
    sg_column *generators; /* (degree - 1) consecutive arrays of count columns */
    sg_embedding restrictions[9];
    size_t restriction_count;
} sg_rep;
typedef struct { sg_rep *items; size_t count, capacity; } sg_level;
typedef struct { sg_level levels[10]; } sg_plan;

static int64_t sg_power(int64_t base, int64_t exponent) {
    int64_t value = 1;
    while (exponent) {
        if (exponent & 1) value = value * base % SG_MOD;
        base = base * base % SG_MOD;
        exponent >>= 1;
    }
    return value;
}

static void sg_free_plan(sg_plan *plan) {
    for (size_t degree = 1; degree <= 9; ++degree) {
        sg_level *level = &plan->levels[degree];
        for (size_t i = 0; i < level->count; ++i) {
            free(level->items[i].basis);
            free(level->items[i].generators);
        }
        free(level->items);
    }
    memset(plan, 0, sizeof(*plan));
}

static void *sg_grow(void *data, size_t *capacity, size_t item_size) {
    size_t next = *capacity ? *capacity * 2 : 4;
    if (next < *capacity || next > SIZE_MAX / item_size) return NULL;
    void *replacement = realloc(data, next * item_size);
    if (!replacement) return NULL;
    *capacity = next;
    return replacement;
}

static int sg_enumerate(sg_level *level, size_t degree, size_t next,
                        uint8_t shape[9], sg_tableau *tableau) {
    if (next == degree) {
        size_t index = 0;
        while (index < level->count && memcmp(level->items[index].shape, shape, 9)) ++index;
        if (index == level->count) {
            if (level->count == level->capacity) {
                void *replacement = sg_grow(level->items, &level->capacity, sizeof(*level->items));
                if (!replacement) return SG_ALLOC;
                level->items = replacement;
            }
            memset(&level->items[index], 0, sizeof(level->items[index]));
            memcpy(level->items[index].shape, shape, 9);
            ++level->count;
        }
        sg_rep *rep = &level->items[index];
        if (rep->count == rep->capacity) {
            void *replacement = sg_grow(rep->basis, &rep->capacity, sizeof(*rep->basis));
            if (!replacement) return SG_ALLOC;
            rep->basis = replacement;
        }
        rep->basis[rep->count++] = *tableau;
        return 0;
    }
    for (size_t row = 0; row < degree; ++row) {
        if (row && shape[row] >= shape[row-1]) continue;
        uint8_t column = shape[row];
        tableau->cell[next] = (uint8_t)(9*row+column);
        ++shape[row];
        int status = sg_enumerate(level, degree, next+1, shape, tableau);
        --shape[row];
        if (status) return status;
        if (!column) break;
    }
    return 0;
}

static int sg_tableau_compare(const sg_tableau *a, const sg_tableau *b, size_t degree) {
    for (size_t i = degree; i-- > 0;) {
        if (a->cell[i] != b->cell[i]) return a->cell[i] < b->cell[i] ? -1 : 1;
    }
    return 0;
}

static int sg_prepare_level(sg_level *level, size_t degree) {
    uint8_t shape[9] = {0};
    sg_tableau tableau = {{0}};
    int status = sg_enumerate(level, degree, 0, shape, &tableau);
    if (status) return status;
    /* Group order and tableau order match the lexicographic reference plans. */
    for (size_t i = 1; i < level->count; ++i) {
        sg_rep current = level->items[i]; size_t j = i;
        while (j && memcmp(level->items[j-1].shape, current.shape, 9) > 0) {
            level->items[j] = level->items[j-1]; --j;
        }
        level->items[j] = current;
    }
    for (size_t r = 0; r < level->count; ++r) {
        sg_rep *rep = &level->items[r];
        for (size_t i = 1; i < rep->count; ++i) {
            sg_tableau current = rep->basis[i]; size_t j = i;
            while (j && sg_tableau_compare(&rep->basis[j-1], &current, degree) > 0) {
                rep->basis[j] = rep->basis[j-1]; --j;
            }
            rep->basis[j] = current;
        }
        if (degree == 1) continue;
        if (rep->count > SIZE_MAX / (degree-1) / sizeof(*rep->generators)) return SG_ALLOC;
        rep->generators = malloc((degree-1)*rep->count*sizeof(*rep->generators));
        if (!rep->generators) return SG_ALLOC;
        for (size_t label = 0; label+1 < degree; ++label) {
            for (size_t i = 0; i < rep->count; ++i) {
                int first = rep->basis[i].cell[label], second = rep->basis[i].cell[label+1];
                int distance = second%9-second/9-first%9+first/9;
                if (!distance) return SG_INVARIANT;
                sg_column *column = &rep->generators[label*rep->count+i];
                column->diagonal = sg_power((distance+SG_MOD)%SG_MOD, SG_MOD-2);
                column->partner = SIZE_MAX; column->coefficient = 0;
                if (distance == 1 || distance == -1) continue;
                sg_tableau swapped = rep->basis[i];
                uint8_t cell = swapped.cell[label]; swapped.cell[label] = swapped.cell[label+1];
                swapped.cell[label+1] = cell;
                size_t lo = 0, hi = rep->count;
                while (lo < hi) {
                    size_t mid = lo+(hi-lo)/2;
                    if (sg_tableau_compare(&rep->basis[mid], &swapped, degree) < 0) lo = mid+1;
                    else hi = mid;
                }
                if (lo == rep->count || sg_tableau_compare(&rep->basis[lo], &swapped, degree)) return SG_INVARIANT;
                column->partner = lo;
                column->coefficient = distance > 0 ? 1 :
                    (1-column->diagonal*column->diagonal%SG_MOD+SG_MOD)%SG_MOD;
            }
        }
    }
    return 0;
}

static int sg_make_plan(sg_plan *plan, size_t degree) {
    memset(plan, 0, sizeof(*plan));
    if (degree < 1 || degree > 9) return SG_INVARIANT;
    for (size_t n = 1; n <= degree; ++n) {
        int status = sg_prepare_level(&plan->levels[n], n);
        if (status) { sg_free_plan(plan); return status; }
        if (n == 1) continue;
        sg_level *parents = &plan->levels[n], *children = &plan->levels[n-1];
        for (size_t i = 0; i < parents->count; ++i) {
            sg_rep *parent = &parents->items[i];
            for (size_t start = 0; start < parent->count;) {
                uint8_t corner = parent->basis[start].cell[n-1]; size_t end = start+1;
                while (end < parent->count && parent->basis[end].cell[n-1] == corner) ++end;
                uint8_t child_shape[9]; memcpy(child_shape, parent->shape, 9);
                if (corner/9 >= 9 || !child_shape[corner/9]) { sg_free_plan(plan); return SG_INVARIANT; }
                --child_shape[corner/9];
                size_t child = 0;
                while (child < children->count && memcmp(children->items[child].shape, child_shape, 9)) ++child;
                if (child == children->count || children->items[child].count != end-start || parent->restriction_count == 9) {
                    sg_free_plan(plan); return SG_INVARIANT;
                }
                for (size_t j = 0; j < end-start; ++j)
                    if (memcmp(parent->basis[start+j].cell, children->items[child].basis[j].cell, n-1)) {
                        sg_free_plan(plan); return SG_INVARIANT;
                    }
                parent->restrictions[parent->restriction_count++] = (sg_embedding){child,start,end-start};
                start = end;
            }
        }
    }
    return 0;
}
#endif
