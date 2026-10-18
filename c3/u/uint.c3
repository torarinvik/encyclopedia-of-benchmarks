module uint_base_conversion;

const usz MAX_DIGITS = 64;
const usz MAX_OUTPUT_DIGITS = 1665;
struct Big { uint[MAX_OUTPUT_DIGITS] digits; usz len; }

fn void trim(Big* value) {
    while (value.len > 0 && value.digits[value.len - 1] == 0) value.len--;
}

fn Big from_small(uint value, uint base) {
    Big result = {};
    while (value > 0) { result.digits[result.len++] = value % base; value /= base; }
    return result;
}

fn void add(Big* left, Big* right, uint base) {
    usz index = 0; ulong carry = 0;
    while (index < right.len || carry > 0) {
        ulong a = index < left.len ? left.digits[index] : 0;
        ulong b = index < right.len ? right.digits[index] : 0;
        ulong sum = carry + a + b;
        if (index == left.len) left.len++;
        left.digits[index] = (uint)(sum % base);
        carry = sum / base;
        index++;
    }
    while (left.len < right.len) { left.digits[left.len] = right.digits[left.len]; left.len++; }
}

fn Big multiply(Big* left, Big* right, uint base) {
    Big result = {};
    if (left.len == 0 || right.len == 0) return result;
    result.len = left.len + right.len;
    for (usz i = 0; i < left.len; i++) {
        ulong carry = 0;
        for (usz j = 0; j < right.len; j++) {
            usz at = i + j;
            ulong product = (ulong)left.digits[i] * right.digits[j] + result.digits[at] + carry;
            result.digits[at] = (uint)(product % base);
            carry = product / base;
        }
        usz at = i + right.len;
        while (carry > 0) {
            ulong sum = result.digits[at] + carry;
            result.digits[at] = (uint)(sum % base);
            carry = sum / base;
            at++;
            if (at > result.len) result.len = at;
        }
    }
    trim(&result);
    return result;
}

fn Big power(Big factor, usz exponent, uint base) {
    Big result = from_small(1, base);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(&result, &factor, base);
        exponent >>= 1;
        if (exponent > 0) factor = multiply(&factor, &factor, base);
    }
    return result;
}

fn Big convert_base(uint* digits, usz length, uint source_base, uint target_base) {
    if (length == 0) return Big{};
    if (source_base == target_base) {
        Big copy = {}; copy.len = length;
        for (usz i = 0; i < length; i++) copy.digits[i] = digits[i];
        return copy;
    }
    if (length == 1) return from_small(digits[0], target_base);
    usz middle = length / 2;
    Big low = convert_base(digits, middle, source_base, target_base);
    Big high = convert_base(&digits[middle], length - middle, source_base, target_base);
    Big scale = power(from_small(source_base, target_base), middle, target_base);
    Big shifted = multiply(&high, &scale, target_base);
    add(&low, &shifted, target_base);
    return low;
}

fn long uint_convert_base(long* input, usz length, char* output, usz capacity) @export("uint_convert_base") {
    if (input == null || length < 3 || length > MAX_DIGITS + 4) return -1;
    long source_value = input[0], target_value = input[1], count_value = input[2];
    if (source_value < 2 || source_value > (1L << 26) || target_value < 2 || target_value > (1L << 26) ||
        count_value < 0 || count_value > MAX_DIGITS || length != (usz)count_value + 3) return -1;
    uint source_base = (uint)source_value, target_base = (uint)target_value;
    usz count = (usz)count_value;
    uint[MAX_DIGITS] source_digits = {};
    for (usz i = 0; i < count; i++) {
        if (input[i + 3] < 0 || input[i + 3] >= source_value) return -1;
        source_digits[i] = (uint)input[i + 3];
    }
    if (count > 0 && source_digits[count - 1] == 0) return -1;
    Big result = convert_base(&source_digits[0], count, source_base, target_base);
    if (result.len > MAX_OUTPUT_DIGITS) return -1;
    usz bytes = result.len * 4;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < result.len; i++) {
        for (usz byte = 0; byte < 4; byte++) output[i * 4 + byte] = (char)(result.digits[i] >> (byte * 8));
    }
    return (long)bytes;
}
