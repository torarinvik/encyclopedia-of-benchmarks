module shootout_objinst;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

const long MIN_N = -100000;
const long MAX_N = 100000;
const usz OUTPUT_BYTES = 72;

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

void toggle_activate(void* opaque) {
    Toggle* toggle = (Toggle*)opaque;
    toggle->state = !toggle->state;
}
int toggle_value(void* opaque) {
    Toggle* toggle = (Toggle*)opaque;
    return toggle->state;
}

void nth_toggle_activate(void* opaque) {
    NthToggle* toggle = (NthToggle*)opaque;
    toggle->counter++;
    if (toggle->counter >= toggle->count_max) {
        toggle->state = !toggle->state;
        toggle->counter = 0;
    }
}
int nth_toggle_value(void* opaque) {
    NthToggle* toggle = (NthToggle*)opaque;
    return toggle->state;
}

void append_state(char* staged, usz* used, int state) {
    if (state != 0) {
        staged[(*used)++] = 't'; staged[(*used)++] = 'r';
        staged[(*used)++] = 'u'; staged[(*used)++] = 'e';
    } else {
        staged[(*used)++] = 'f'; staged[(*used)++] = 'a';
        staged[(*used)++] = 'l'; staged[(*used)++] = 's'; staged[(*used)++] = 'e';
    }
    staged[(*used)++] = '\n';
}

fn long shootout_objinst(long n, char* output, usz output_capacity)
    @export("shootout_objinst") {
    if (n < MIN_N || n > MAX_N) return -1;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;

    char[OUTPUT_BYTES] staged;
    usz used = 0;
    Toggle* toggle = (Toggle*)malloc(sizeof(Toggle));
    if (toggle == null) return -1;
    toggle->state = 1; toggle->activate = &toggle_activate; toggle->value = &toggle_value;
    for (int call = 0; call < 5; call++) {
        toggle->activate(toggle);
        append_state(&staged[0], &used, toggle->value(toggle));
    }
    free(toggle);

    for (long index = 0; index < n; index++) {
        Toggle* extra = (Toggle*)malloc(sizeof(Toggle));
        if (extra == null) return -1;
        extra->state = 1; extra->activate = &toggle_activate; extra->value = &toggle_value;
        free(extra);
    }

    staged[used++] = '\n';
    NthToggle* nth_toggle = (NthToggle*)malloc(sizeof(NthToggle));
    if (nth_toggle == null) return -1;
    nth_toggle->state = 1; nth_toggle->count_max = 3; nth_toggle->counter = 0;
    nth_toggle->activate = &nth_toggle_activate; nth_toggle->value = &nth_toggle_value;
    for (int call = 0; call < 8; call++) {
        nth_toggle->activate(nth_toggle);
        append_state(&staged[0], &used, nth_toggle->value(nth_toggle));
    }
    free(nth_toggle);

    for (long index = 0; index < n; index++) {
        NthToggle* extra = (NthToggle*)malloc(sizeof(NthToggle));
        if (extra == null) return -1;
        extra->state = 1; extra->count_max = 3; extra->counter = 0;
        extra->activate = &nth_toggle_activate; extra->value = &nth_toggle_value;
        free(extra);
    }

    if (used != OUTPUT_BYTES) return -1;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}
