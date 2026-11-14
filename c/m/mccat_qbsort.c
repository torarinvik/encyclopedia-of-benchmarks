#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_ITEMS 32

static void bubble(int32_t *a, size_t n) {
    for (size_t end = n; end > 1; --end)
        for (size_t i = 0; i + 1 < end; ++i)
            if (a[i + 1] < a[i]) { int32_t t = a[i]; a[i] = a[i + 1]; a[i + 1] = t; }
}

typedef struct node { int32_t value; struct node *next; } node;

static void free_nodes(node *list) {
    while (list) { node *next = list->next; free(list); list = next; }
}

static node *prepend(node *list, int32_t value, int *failed) {
    node *item = malloc(sizeof *item);
    if (!item) { *failed = 1; return list; }
    item->value = value;
    item->next = list;
    return item;
}

static node *quick(const node *items, int *failed) {
    if (!items || *failed) return NULL;
    const int32_t pivot = items->value;
    node *lower = NULL, *upper = NULL;
    for (const node *item = items->next; item && !*failed; item = item->next) {
        if (item->value < pivot) lower = prepend(lower, item->value, failed);
        else upper = prepend(upper, item->value, failed);
    }
    node *sorted_upper = quick(upper, failed);
    node *sorted_lower = quick(lower, failed);
    free_nodes(upper);
    free_nodes(lower);
    if (*failed) { free_nodes(sorted_upper); free_nodes(sorted_lower); return NULL; }
    node *pivot_node = prepend(sorted_upper, pivot, failed);
    if (*failed) { free_nodes(sorted_upper); free_nodes(sorted_lower); return NULL; }
    if (!sorted_lower) return pivot_node;
    node *tail = sorted_lower;
    while (tail->next) tail = tail->next;
    tail->next = pivot_node;
    return sorted_lower;
}

int64_t mccat_qbsort(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > 2 + MAX_ITEMS) return -1;
    const int64_t mode = input[0], count_value = input[1];
    if ((mode != 0 && mode != 1) || count_value < 1 || count_value > MAX_ITEMS) return -1;
    const size_t n = (size_t)count_value;
    if (length != n + 2) return -1;
    int32_t values[MAX_ITEMS];
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
        values[i] = (int32_t)input[i + 2];
    }
    for (size_t pass = 0; pass < 1000; ++pass) {
        for (size_t i = 0; i < n; ++i) values[i] = (int32_t)input[i + 2];
        if (mode == 0) bubble(values, n);
        else {
            node *items = NULL;
            int failed = 0;
            for (size_t i = n; i > 0 && !failed; --i) items = prepend(items, values[i - 1], &failed);
            node *sorted = quick(items, &failed);
            free_nodes(items);
            if (failed) { free_nodes(sorted); return -1; }
            size_t i = 0;
            for (const node *item = sorted; item; item = item->next) values[i++] = item->value;
            free_nodes(sorted);
        }
    }
    const size_t required = 4 * n;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < n; ++i) {
        uint32_t bits = (uint32_t)values[i];
        for (size_t b = 0; b < 4; ++b) output[4 * i + b] = (uint8_t)(bits >> (8 * b));
    }
    return (int64_t)required;
}
