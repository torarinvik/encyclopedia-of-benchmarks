module problem43;

fn bool next_permutation(long* digits) {
    long pivot = 8;
    while (pivot >= 0 && digits[(usz)pivot] >= digits[(usz)(pivot + 1)]) pivot--;
    if (pivot < 0) return false;
    long successor = 9;
    while (digits[(usz)successor] <= digits[(usz)pivot]) successor--;
    long temporary = digits[(usz)pivot];
    digits[(usz)pivot] = digits[(usz)successor];
    digits[(usz)successor] = temporary;
    long left = pivot + 1, right = 9;
    while (left < right) {
        temporary = digits[(usz)left]; digits[(usz)left] = digits[(usz)right]; digits[(usz)right] = temporary;
        left++; right--;
    }
    return true;
}

fn long problem43(long n) @export("problem43") {
    if (n != 10) return -1;
    long[10] digits; for (usz i = 0; i < 10; ++i) digits[i] = (long)i;
    long[4] divisors = {7, 11, 13, 17};
    long total = 0; bool more = true;
    while (more) {
        if (digits[3] % 2 == 0 && (digits[2]+digits[3]+digits[4]) % 3 == 0 && digits[5] % 5 == 0) {
            bool valid = true;
            for (usz i = 0; i < 4; ++i)
                if ((digits[i+4]*100+digits[i+5]*10+digits[i+6]) % divisors[i] != 0) valid = false;
            if (valid) { long value = 0; for (usz i = 0; i < 10; ++i) value = value*10+digits[i]; total += value; }
        }
        more = next_permutation(&digits[0]);
    }
    return total;
}
