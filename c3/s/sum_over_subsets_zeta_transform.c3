module sum_over_subsets_zeta_transform;

const usz MAX_MASKS = 64;
const usz MAX_INPUT_LENGTH = 66;
const usz MAX_BITS = 6;

fn long sum_over_subsets_zeta_transform(long* input, usz length) @export("sum_over_subsets_zeta_transform") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long bit_count_value = input[0];
    if (bit_count_value < 0 || bit_count_value > (long)MAX_BITS) return -1;
    usz bit_count = (usz)bit_count_value;
    usz mask_count = (usz)1 << bit_count;
    if (length != mask_count + 1) return -1;

    long[MAX_MASKS] transformed = {};
    for (usz mask = 0; mask < mask_count; mask++) {
        long value = input[mask + 1];
        if (value < 0 || value > 1000000) return -1;
        transformed[mask] = value;
    }

    for (usz bit = 0; bit < bit_count; bit++) {
        usz bit_value = (usz)1 << bit;
        for (usz mask = 0; mask < mask_count; mask++) {
            if ((mask & bit_value) != 0)
                transformed[mask] += transformed[mask ^ bit_value];
        }
    }

    long checksum = 0;
    for (usz mask = 0; mask < mask_count; mask++)
        checksum += (long)(mask + 1) * transformed[mask];
    return checksum;
}
