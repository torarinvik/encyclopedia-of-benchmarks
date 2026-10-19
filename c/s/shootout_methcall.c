#include <stddef.h>
#include <stdint.h>

#define MIN_CALLS INT64_C(-100000)
#define MAX_CALLS INT64_C(100000)
#define MAX_OUTPUT_BYTES 14

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
    if (state) {
        staged[(*used)++] = 't'; staged[(*used)++] = 'r'; staged[(*used)++] = 'u'; staged[(*used)++] = 'e';
    } else {
        staged[(*used)++] = 'f'; staged[(*used)++] = 'a'; staged[(*used)++] = 'l'; staged[(*used)++] = 's'; staged[(*used)++] = 'e';
    }
    staged[(*used)++] = '\n';
    staged[(*used)++] = '\n';
}

int64_t shootout_methcall(int64_t calls, uint8_t *output, size_t output_capacity) {
    if (calls < MIN_CALLS || calls > MAX_CALLS) return -1;
    if (output == NULL) return -2;

    Toggle toggle = {1, toggle_activate, toggle_value};
    NthToggle nth_toggle = {1, 3, 0, nth_toggle_activate, nth_toggle_value};
    int32_t toggle_result = 1;
    int32_t nth_result = 1;
    for (int64_t index = 0; index < calls; ++index) {
        Toggle *active = toggle.activate(&toggle);
        toggle_result = toggle.value(active);
    }
    for (int64_t index = 0; index < calls; ++index) {
        NthToggle *active = nth_toggle.activate(&nth_toggle);
        nth_result = nth_toggle.value(active);
    }

    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    append_state(staged, &used, toggle_result);
    append_state(staged, &used, nth_result);
    if (output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
