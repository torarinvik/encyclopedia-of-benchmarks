#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MIN_N INT64_C(-100000)
#define MAX_N INT64_C(100000)
#define OUTPUT_BYTES 72

typedef struct Toggle Toggle;
typedef struct NthToggle NthToggle;
typedef Toggle *(*ToggleActivate)(Toggle *);
typedef int32_t (*ToggleValue)(const Toggle *);
typedef NthToggle *(*NthToggleActivate)(NthToggle *);
typedef int32_t (*NthToggleValue)(const NthToggle *);

struct Toggle {
    int32_t state;
    ToggleActivate activate;
    ToggleValue value;
};

struct NthToggle {
    int32_t state;
    int32_t count_max;
    int32_t counter;
    NthToggleActivate activate;
    NthToggleValue value;
};

static Toggle *toggle_activate(Toggle *toggle) {
    toggle->state = !toggle->state;
    return toggle;
}

static int32_t toggle_value(const Toggle *toggle) { return toggle->state; }

static NthToggle *nth_toggle_activate(NthToggle *toggle) {
    if (++toggle->counter >= toggle->count_max) {
        toggle->state = !toggle->state;
        toggle->counter = 0;
    }
    return toggle;
}

static int32_t nth_toggle_value(const NthToggle *toggle) { return toggle->state; }

static void append_state(uint8_t *staged, size_t *used, int32_t state) {
    const char *word = state ? "true" : "false";
    while (*word != '\0') staged[(*used)++] = (uint8_t)*word++;
    staged[(*used)++] = '\n';
}

int64_t shootout_objinst(int64_t n, uint8_t *output, size_t output_capacity) {
    if (n < MIN_N || n > MAX_N) return -1;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;

    uint8_t staged[OUTPUT_BYTES];
    size_t used = 0;
    Toggle *toggle = (Toggle *)malloc(sizeof(*toggle));
    if (toggle == NULL) return -1;
    *toggle = (Toggle){1, toggle_activate, toggle_value};
    for (int32_t call = 0; call < 5; ++call) {
        Toggle *active = toggle->activate(toggle);
        append_state(staged, &used, toggle->value(active));
    }
    free(toggle);

    for (int64_t index = 0; index < n; ++index) {
        Toggle *extra = (Toggle *)malloc(sizeof(*extra));
        if (extra == NULL) return -1;
        *extra = (Toggle){1, toggle_activate, toggle_value};
        free(extra);
    }

    staged[used++] = '\n';
    NthToggle *nth_toggle = (NthToggle *)malloc(sizeof(*nth_toggle));
    if (nth_toggle == NULL) return -1;
    *nth_toggle = (NthToggle){1, 3, 0, nth_toggle_activate, nth_toggle_value};
    for (int32_t call = 0; call < 8; ++call) {
        NthToggle *active = nth_toggle->activate(nth_toggle);
        append_state(staged, &used, nth_toggle->value(active));
    }
    free(nth_toggle);

    for (int64_t index = 0; index < n; ++index) {
        NthToggle *extra = (NthToggle *)malloc(sizeof(*extra));
        if (extra == NULL) return -1;
        *extra = (NthToggle){1, 3, 0, nth_toggle_activate, nth_toggle_value};
        free(extra);
    }

    if (used != OUTPUT_BYTES) return -1;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
