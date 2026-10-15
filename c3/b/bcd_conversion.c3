module bcd_conversion;

const long INVALID_RESULT = -1;

fn long bcd_conversion(long decimal) @export("bcd_conversion") {
    if (decimal < 0 || decimal > 9999) return INVALID_RESULT;
    long bcd = 0;
    long shift = 0;
    while (decimal > 0) {
        long digit = decimal % 10;
        bcd |= digit << (shift * 4);
        decimal /= 10;
        shift++;
    }
    return bcd;
}
