module area;

const usz MAX_OPERATIONS = 256;
const long DIMENSION_LIMIT = 1000;
const long RESULT_OFFSET = 1000000007;

fn long integer_sqrt(long value) {
    long low = 0;
    long high = 3037000499;
    long answer = 0;
    while (low <= high) {
        long middle = low + (high - low) / 2;
        if (middle == 0 || middle <= value / middle) {
            answer = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return answer;
}

fn long scale_pi(long value) {
    return value * 3 + value * 141592654 / 1000000000;
}

fn long scale_pi_squared(long value) {
    return value * 9 + value * 869604401 / 1000000000;
}

fn long regular_polygon_coefficient(long sides) {
    if (sides == 3) return 433012701;
    if (sides == 4) return 1000000000;
    if (sides == 5) return 1720477400;
    if (sides == 6) return 2598076211;
    if (sides == 7) return 3633912444;
    if (sides == 8) return 4828427124;
    if (sides == 9) return 6181824193;
    if (sides == 10) return 7694208842;
    if (sides == 11) return 9365639906;
    if (sides == 12) return 11196152422;
    if (sides == 13) return 13185768328;
    if (sides == 14) return 15334501936;
    if (sides == 15) return 17642362910;
    if (sides == 16) return 20109357968;
    if (sides == 17) return 22735491898;
    if (sides == 18) return 25520768188;
    if (sides == 19) return 28465189427;
    if (sides == 20) return 31568757573;
    if (sides == 21) return 34831474123;
    if (sides == 22) return 38253340244;
    if (sides == 23) return 41834356852;
    if (sides == 24) return 45574524676;
    if (sides == 25) return 49473844301;
    if (sides == 26) return 53532316204;
    if (sides == 27) return 57749940771;
    if (sides == 28) return 62126718324;
    if (sides == 29) return 66662649129;
    if (sides == 30) return 71357733406;
    if (sides == 31) return 76211971344;
    if (sides == 32) return 81225363100;
    return -1;
}

fn long area_milli(long operation, long a, long b, long c) {
    if (operation == 0) return a * a * 1000;
    if (operation == 1) return a * b * 1000;
    if (operation == 2) return a * b * 500;
    if (operation == 3) return scale_pi(a * a * 1000);
    if (operation == 4) return a * b * 1000;
    if (operation == 5) return (a + b) * c * 500;
    if (operation == 6) {
        long perimeter = a + b + c;
        if (a + b < c || a + c < b || b + c < a) return -1;
        long radicand = perimeter * (perimeter - 2 * a) * (perimeter - 2 * b) * (perimeter - 2 * c);
        return integer_sqrt(radicand * 1000000) / 4;
    }
    if (operation == 7) return scale_pi(a * b * 1000);
    if (operation == 8) return a * b * 500;
    if (operation == 9) return 6 * a * a * 1000;
    if (operation == 10) return 2 * (a * b + a * c + b * c) * 1000;
    if (operation == 11) return scale_pi(4 * a * a * 1000);
    if (operation == 12) return scale_pi(3 * a * a * 1000);
    if (operation == 13) return scale_pi(2 * a * (b + a) * 1000);
    if (operation == 14) return scale_pi(2 * a * b * 1000);
    if (operation == 15) return scale_pi(a * a * 1000 + a * integer_sqrt((a * a + b * b) * 1000000));
    if (operation == 16) return scale_pi(a * integer_sqrt((a * a + b * b) * 1000000));
    if (operation == 17) return (a * a + 2 * a * b) * 1000;
    if (operation == 18) {
        long difference = a >= b ? a - b : b - a;
        long slant_milli = integer_sqrt((c * c + difference * difference) * 1000000);
        return scale_pi((a * a + b * b) * 1000 + (a + b) * slant_milli);
    }
    if (operation == 19) return scale_pi_squared(4 * a * b * 1000);
    if (operation == 20) {
        long coefficient = regular_polygon_coefficient(a);
        if (coefficient < 0) return -1;
        return coefficient * b * b / 1000000;
    }
    if (operation == 21) {
        long coefficient = regular_polygon_coefficient(a);
        if (coefficient < 0) return -1;
        return 2 * (coefficient * b * b / 1000000) + a * b * c * 1000;
    }
    return -1;
}

fn long area_benchmark(long* values, usz length) @export("area_benchmark") {
    if (length < 1 || length > 1025) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > 256 || length != 1 + 4 * (usz)count_value) return -1;
    long checksum = 0;
    for (usz index = 0; index < (usz)count_value; index++) {
        usz position = 1 + 4 * index;
        long operation = values[position];
        long a = values[position + 1];
        long b = values[position + 2];
        long c = values[position + 3];
        if (operation < 0 || operation > 21 || a < 0 || a > DIMENSION_LIMIT
            || b < 0 || b > DIMENSION_LIMIT || c < 0 || c > DIMENSION_LIMIT) return -1;
        if ((operation == 0 || operation == 3 || operation == 9 || operation == 11 || operation == 12)
            && (b != 0 || c != 0)) return -1;
        if ((operation == 1 || operation == 2 || operation == 4 || operation == 7 || operation == 8
            || (operation >= 13 && operation <= 17) || operation == 19 || operation == 20) && c != 0) return -1;
        long result = area_milli(operation, a, b, c);
        if (result < 0) return -1;
        checksum += (long)(index + 1) * (result + RESULT_OFFSET);
    }
    return checksum;
}
