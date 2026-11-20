#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_VERTICES 7
#define MAX_SHAPES 48
#define MAX_ENCODING 14
#define MAX_WIDTH (MAX_ENCODING + 1)
#define MAX_CANDIDATES 37
#define MAX_OUTPUT 674

typedef struct {
    size_t size;
    const char *text;
} Candidate;

typedef struct {
    char shapes[MAX_VERTICES + 1][MAX_SHAPES][MAX_WIDTH];
    size_t counts[MAX_VERTICES + 1];
    Candidate candidates[MAX_CANDIDATES];
    size_t candidate_count;
    size_t target;
} Generator;

static int text_less(const char *left, const char *right) {
    return strcmp(left, right) < 0;
}

static void enumerate_multisets(Generator *generator, size_t start,
                                size_t remaining, char *children,
                                size_t child_length) {
    if (remaining == 0) {
        size_t index = generator->counts[generator->target];
        if (index >= MAX_SHAPES) return;
        char *shape = generator->shapes[generator->target][index];
        shape[0] = '(';
        memcpy(shape + 1, children, child_length);
        shape[child_length + 1] = ')';
        shape[child_length + 2] = '\0';
        generator->counts[generator->target] = index + 1;
        return;
    }

    for (size_t index = start; index < generator->candidate_count; ++index) {
        const Candidate *candidate = &generator->candidates[index];
        if (candidate->size > remaining) continue;
        const size_t encoded_length = 2 * candidate->size;
        memcpy(children + child_length, candidate->text, encoded_length);
        enumerate_multisets(generator, index, remaining - candidate->size,
                            children, child_length + encoded_length);
    }
}

static void sort_shapes(char shapes[MAX_SHAPES][MAX_WIDTH], size_t count) {
    for (size_t index = 1; index < count; ++index) {
        char value[MAX_WIDTH];
        memcpy(value, shapes[index], sizeof(value));
        size_t position = index;
        while (position > 0 && text_less(value, shapes[position - 1])) {
            memcpy(shapes[position], shapes[position - 1], sizeof(value));
            --position;
        }
        memcpy(shapes[position], value, sizeof(value));
    }
}

static void build_shapes(Generator *generator, size_t maximum) {
    generator->counts[1] = 1;
    generator->shapes[1][0][0] = '(';
    generator->shapes[1][0][1] = ')';
    generator->shapes[1][0][2] = '\0';

    for (size_t target = 2; target <= maximum; ++target) {
        generator->target = target;
        generator->candidate_count = 0;
        for (size_t size = 1; size < target; ++size) {
            for (size_t index = 0; index < generator->counts[size]; ++index) {
                Candidate candidate = {size, generator->shapes[size][index]};
                size_t position = generator->candidate_count;
                while (position > 0 &&
                       text_less(candidate.text,
                                 generator->candidates[position - 1].text)) {
                    generator->candidates[position] =
                        generator->candidates[position - 1];
                    --position;
                }
                generator->candidates[position] = candidate;
                ++generator->candidate_count;
            }
        }

        char children[MAX_ENCODING] = {0};
        enumerate_multisets(generator, 0, target - 1, children, 0);
        sort_shapes(generator->shapes[target], generator->counts[target]);
    }
}

int64_t list_rooted_trees(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1) return -1;
    const int64_t requested = input[0];
    if (requested < 1 || requested > MAX_VERTICES) return -1;

    Generator generator = {0};
    const size_t vertices = (size_t)requested;
    build_shapes(&generator, vertices);

    uint8_t staged[MAX_OUTPUT] = {0};
    const size_t count = generator.counts[vertices];
    staged[0] = (uint8_t)(count & 0xffU);
    staged[1] = (uint8_t)((count >> 8) & 0xffU);
    size_t position = 2;
    const size_t width = 2 * vertices;
    for (size_t index = 0; index < count; ++index) {
        memcpy(staged + position, generator.shapes[vertices][index], width);
        position += width;
    }

    if (output == NULL || capacity < position) return -2;
    memcpy(output, staged, position);
    return (int64_t)position;
}
