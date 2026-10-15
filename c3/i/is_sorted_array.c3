module is_sorted_array;

const usz MAX_LENGTH = 100000;
const long MAX_SAFE_INTEGER = 9007199254740991;

fn long is_sorted_array(long* values, usz length) @export("is_sorted_array") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] < -MAX_SAFE_INTEGER || values[i] > MAX_SAFE_INTEGER) return -1;
    }
    for (usz i = 0; i + 1 < length; i++) {
        if (values[i] >= values[i + 1]) return 0;
    }
    return 1;
}
