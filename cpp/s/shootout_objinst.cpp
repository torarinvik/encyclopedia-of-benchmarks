#include <cstddef>
#include <cstdint>
#include <new>

namespace {
constexpr int64_t MIN_N = -100000;
constexpr int64_t MAX_N = 100000;
constexpr size_t OUTPUT_BYTES = 72;

struct Toggle;
struct NthToggle;
using ToggleActivate = Toggle *(*)(Toggle *);
using ToggleValue = int32_t (*)(const Toggle *);
using NthToggleActivate = NthToggle *(*)(NthToggle *);
using NthToggleValue = int32_t (*)(const NthToggle *);

struct Toggle { int32_t state; ToggleActivate activate; ToggleValue value; };
struct NthToggle {
    int32_t state;
    int32_t count_max;
    int32_t counter;
    NthToggleActivate activate;
    NthToggleValue value;
};

Toggle *toggleActivate(Toggle *toggle) {
    toggle->state = !toggle->state;
    return toggle;
}
int32_t toggleValue(const Toggle *toggle) { return toggle->state; }

NthToggle *nthToggleActivate(NthToggle *toggle) {
    if (++toggle->counter >= toggle->count_max) {
        toggle->state = !toggle->state;
        toggle->counter = 0;
    }
    return toggle;
}
int32_t nthToggleValue(const NthToggle *toggle) { return toggle->state; }

void appendState(uint8_t *staged, size_t &used, int32_t state) {
    const char *word = state ? "true" : "false";
    while (*word != '\0') staged[used++] = static_cast<uint8_t>(*word++);
    staged[used++] = static_cast<uint8_t>('\n');
}
} // namespace

extern "C" int64_t shootout_objinst(int64_t n, uint8_t *output, size_t output_capacity) {
    if (n < MIN_N || n > MAX_N) return -1;
    if (output == nullptr || output_capacity < OUTPUT_BYTES) return -2;

    uint8_t staged[OUTPUT_BYTES];
    size_t used = 0;
    Toggle *toggle = new (std::nothrow) Toggle{1, toggleActivate, toggleValue};
    if (toggle == nullptr) return -1;
    for (int32_t call = 0; call < 5; ++call) {
        Toggle *active = toggle->activate(toggle);
        appendState(staged, used, toggle->value(active));
    }
    delete toggle;

    for (int64_t index = 0; index < n; ++index) {
        Toggle *extra = new (std::nothrow) Toggle{1, toggleActivate, toggleValue};
        if (extra == nullptr) return -1;
        delete extra;
    }

    staged[used++] = static_cast<uint8_t>('\n');
    NthToggle *nthToggle = new (std::nothrow) NthToggle{1, 3, 0, nthToggleActivate, nthToggleValue};
    if (nthToggle == nullptr) return -1;
    for (int32_t call = 0; call < 8; ++call) {
        NthToggle *active = nthToggle->activate(nthToggle);
        appendState(staged, used, nthToggle->value(active));
    }
    delete nthToggle;

    for (int64_t index = 0; index < n; ++index) {
        NthToggle *extra = new (std::nothrow) NthToggle{1, 3, 0, nthToggleActivate, nthToggleValue};
        if (extra == nullptr) return -1;
        delete extra;
    }

    if (used != OUTPUT_BYTES) return -1;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<int64_t>(used);
}
