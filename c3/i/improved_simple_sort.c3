module improved_simple_sort;

const usz MAX_LENGTH = 256;
const long MIN_VALUE = -1000000;
const long MAX_VALUE = 1000000;
const long CHECKSUM_OFFSET = 1000001;
const long INVALID_RESULT = -1;

fn long improved_simple_sort(long* values, usz length) @export("improved_simple_sort") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return INVALID_RESULT;
    long[MAX_LENGTH] working = zeroed;
    for (usz index = 0; index < length; index++) {
        if (values[index] < MIN_VALUE || values[index] > MAX_VALUE) return INVALID_RESULT;
        working[index] = values[index];
    }

    for (usz i = 1; i < length; i++) {
        for (usz j = 0; j + 1 < length; j++) {
            if (working[i] < working[j]) {
                long temporary = working[i];
                working[i] = working[j];
                working[j] = temporary;
            }
        }
    }
    long checksum = 0;
    for (usz index = 0; index < length; index++) {
        checksum += (long)(index + 1) * (working[index] + CHECKSUM_OFFSET);
    }
    return checksum;
}
