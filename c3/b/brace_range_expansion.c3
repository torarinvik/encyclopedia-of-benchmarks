module brace_range_expansion;

struct Endpoint { bool valid; int value; int letter; int width; int upper; }
struct Plan { int open; int close; int start; int step; int letter; int pad; int count; }

fn Endpoint endpoint(long* p, int begin, int end) {
    Endpoint result = {false, 0, 0, 0, 0};
    int n = end - begin;
    if (n == 1 && ((p[begin] >= 65 && p[begin] <= 90) ||
                   (p[begin] >= 97 && p[begin] <= 122))) {
        result.valid = true; result.value = (int)p[begin]; result.letter = 1;
        result.width = 1; result.upper = p[begin] <= 90;
        return result;
    }
    if (n < 1 || n > 4) return result;
    int value = 0;
    for (int i = begin; i < end; i += 1) {
        if (p[i] < 48 || p[i] > 57) return result;
        value = value * 10 + (int)p[i] - 48;
    }
    result.valid = true; result.value = value; result.width = n;
    return result;
}

fn int parse_step(long* p, int begin, int end) {
    int sign = 1;
    if (begin < end && (p[begin] == 43 || p[begin] == 45)) {
        if (p[begin] == 45) sign = -1;
        begin += 1;
    }
    if (end - begin < 1) return 0;
    int value = 0;
    for (int i = begin; i < end; i += 1) {
        if (p[i] < 48 || p[i] > 57) return 0;
        if (value < 10000) {
            value = value * 10 + (int)p[i] - 48;
            if (value > 10000) value = 10000;
        }
    }
    return value == 0 ? 0 : sign * value;
}

fn bool make_plan(long* p, int n, Plan* plan) {
    if (n < 1 || n > 64) return false;
    int open = -1, close = -1;
    for (int i = 0; i < n; i += 1) {
        if (p[i] < 32 || p[i] > 126) return false;
        if (p[i] == 123) { if (open >= 0) return false; open = i; }
        if (p[i] == 125) { if (close >= 0) return false; close = i; }
    }
    if (open < 0 || close <= open || open + n - close - 1 > 32) return false;
    int sep1 = -1, sep2 = -1;
    for (int i = open + 1; i + 1 < close; i += 1) {
        if (p[i] == 46 && p[i+1] == 46) {
            if (sep1 < 0) sep1 = i;
            else if (sep2 < 0) sep2 = i;
            else return false;
            i += 1;
        }
    }
    if (sep1 < 0) return false;
    Endpoint a = endpoint(p, open+1, sep1);
    Endpoint b = endpoint(p, sep1+2, sep2 < 0 ? close : sep2);
    if (!a.valid || !b.valid || a.letter != b.letter ||
        (a.letter != 0 && a.upper != b.upper)) return false;
    int step = sep2 < 0 ? (a.value <= b.value ? 1 : -1) : parse_step(p, sep2+2, close);
    if (step == 0 || (a.value < b.value && step < 0) ||
        (a.value > b.value && step > 0)) return false;
    int count = a.value == b.value ? 1 :
        (a.value < b.value ? (b.value-a.value)/step : (a.value-b.value)/(-step)) + 1;
    if (count > 16) return false;
    int pad = 0;
    if (a.letter == 0 && (p[open+1] == 48 || p[sep1+2] == 48))
        pad = a.width > b.width ? a.width : b.width;
    plan.open = open; plan.close = close; plan.start = a.value;
    plan.step = step; plan.letter = a.letter; plan.pad = pad; plan.count = count;
    return true;
}

fn long brace_range_expansion(long* input, usz length, char* output, usz capacity)
    @export("brace_range_expansion") {
    if (input == null || length < 2 || length > 65) return -1;
    long declared = input[0];
    if (declared < 1 || declared > 64 || length != (usz)(declared+1)) return -1;
    int n = (int)declared;
    Plan plan;
    if (!make_plan(input+1, n, &plan)) return -1;
    char[591] staged = zeroed;
    int out = 0, value = plan.start;
    int suffix_start = plan.close+1, suffix_len = n-suffix_start;
    for (int item = 0; item < plan.count; item += 1) {
        if (item != 0) { staged[out] = 0; out += 1; }
        for (int i = 0; i < plan.open; i += 1) {
            staged[out] = (char)input[1+i]; out += 1;
        }
        if (plan.letter != 0) { staged[out] = (char)value; out += 1; }
        else {
            int[4] digits = zeroed; int used = 0, remaining = value;
            while (true) {
                digits[used] = remaining % 10; used += 1; remaining /= 10;
                if (remaining == 0) break;
            }
            while (used < plan.pad) { staged[out] = 48; out += 1; }
            while (used > 0) { used -= 1; staged[out] = (char)(48+digits[used]); out += 1; }
        }
        for (int i = 0; i < suffix_len; i += 1) {
            staged[out] = (char)input[1+suffix_start+i]; out += 1;
        }
        value += plan.step;
    }
    if (output == null || capacity < (usz)out) return -2;
    for (int i = 0; i < out; i += 1) output[i] = staged[i];
    return (long)out;
}
