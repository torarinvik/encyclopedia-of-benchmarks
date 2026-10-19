#include <cstddef>
#include <cstdint>

namespace {
constexpr int64_t MIN_CALLS = -100000;
constexpr int64_t MAX_CALLS = 100000;
constexpr size_t MAX_OUTPUT_BYTES = 14;

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
    staged[used++] = static_cast<uint8_t>('\n');
}
} // namespace

extern "C" int64_t shootout_methcall(int64_t calls, uint8_t *output, size_t output_capacity) {
    if (calls < MIN_CALLS || calls > MAX_CALLS) return -1;
    if (output == nullptr) return -2;
    Toggle toggle{1, toggleActivate, toggleValue};
    NthToggle nthToggle{1, 3, 0, nthToggleActivate, nthToggleValue};
    int32_t toggleResult = 1, nthResult = 1;
    for (int64_t index = 0; index < calls; ++index) {
        Toggle *active = toggle.activate(&toggle);
        toggleResult = toggle.value(active);
    }
    for (int64_t index = 0; index < calls; ++index) {
        NthToggle *active = nthToggle.activate(&nthToggle);
        nthResult = nthToggle.value(active);
    }
    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    appendState(staged, used, toggleResult);
    appendState(staged, used, nthResult);
    if (output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<int64_t>(used);
}
