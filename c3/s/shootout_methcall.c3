module shootout_methcall;

const long MIN_CALLS = -100000;
const long MAX_CALLS = 100000;
const usz MAX_OUTPUT_BYTES = 14;

alias ToggleActivate = fn void(void* toggle);
alias ToggleValue = fn int(void* toggle);
alias NthToggleActivate = fn void(void* toggle);
alias NthToggleValue = fn int(void* toggle);

struct Toggle { int state; ToggleActivate activate; ToggleValue value; }
struct NthToggle {
    int state;
    int count_max;
    int counter;
    NthToggleActivate activate;
    NthToggleValue value;
}

void toggle_activate(void* opaque_toggle) {
    Toggle* toggle = opaque_toggle;
    toggle->state = !toggle->state;
}

int toggle_value(void* opaque_toggle) {
    Toggle* toggle = opaque_toggle;
    return toggle->state;
}

void nth_toggle_activate(void* opaque_toggle) {
    NthToggle* toggle = opaque_toggle;
    toggle->counter++;
    if (toggle->counter >= toggle->count_max) {
        toggle->state = !toggle->state;
        toggle->counter = 0;
    }
}

int nth_toggle_value(void* opaque_toggle) {
    NthToggle* toggle = opaque_toggle;
    return toggle->state;
}

void append_state(char* staged, usz* used, int state) {
    if (state != 0) {
        staged[(*used)++] = 't'; staged[(*used)++] = 'r'; staged[(*used)++] = 'u'; staged[(*used)++] = 'e';
    } else {
        staged[(*used)++] = 'f'; staged[(*used)++] = 'a'; staged[(*used)++] = 'l'; staged[(*used)++] = 's'; staged[(*used)++] = 'e';
    }
    staged[(*used)++] = '\n';
    staged[(*used)++] = '\n';
}

fn long shootout_methcall(long calls, char* output, usz output_capacity)
    @export("shootout_methcall") {
    if (calls < MIN_CALLS || calls > MAX_CALLS) return -1;
    if (output == null) return -2;
    Toggle toggle = {1, &toggle_activate, &toggle_value};
    NthToggle nth_toggle = {1, 3, 0, &nth_toggle_activate, &nth_toggle_value};
    int toggle_result = 1, nth_result = 1;
    for (long index = 0; index < calls; index++) {
        toggle.activate(&toggle);
        toggle_result = toggle.value(&toggle);
    }
    for (long index = 0; index < calls; index++) {
        nth_toggle.activate(&nth_toggle);
        nth_result = nth_toggle.value(&nth_toggle);
    }
    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    append_state(&staged[0], &used, toggle_result);
    append_state(&staged[0], &used, nth_result);
    if (output_capacity < used) return -2;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}
