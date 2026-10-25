module nsichneu;

const usz INPUT_COUNT = 9;
const usz OUTPUT_COUNT = 17;
const usz OUTPUT_BYTES = OUTPUT_COUNT * 8;
const long MAX_RUNS = 64;
const long MIN_MARK = -1000;
const long MAX_MARK = 1000;

fn long nsichneu(long* input, usz length, char* output, usz capacity) @export("nsichneu") {
    if (input == null || length != INPUT_COUNT || input[0] < 1 || input[0] > MAX_RUNS) return -1;
    for (usz index = 1; index < length; index++) if (input[index] < MIN_MARK || input[index] > MAX_MARK) return -1;
    if (output == null || capacity < OUTPUT_BYTES) return -2;

    long[3] p1 = {input[1], input[2], input[3]};
    long[5] p2 = {input[4], input[5], input[6], input[7], input[8]};
    long[6] p3 = {};
    long p1_count = 3;
    long p2_count = 5;
    long p3_count = 0;

    for (long run = 0; run < input[0]; run++) {
        p1_count = 3;
        p2_count = 5;
        p3_count = 0;
        for (usz first = 0; first < 3; first++) {
            for (usz second = 0; second < 3; second++) {
                if (second == first) continue;
                for (usz third = 0; third < 3; third++) {
                    if (third == first || third == second) continue;
                    if (p1_count >= 3 && p3_count + 3 <= 6 && p1[second] == p1[third]) {
                        long x = p1[first];
                        long y = p1[second];
                        if (x < y) {
                            p1_count -= 3;
                            p3[(usz)p3_count] = x;
                            p3[(usz)p3_count + 1] = y;
                            p3[(usz)p3_count + 2] = x - y;
                            p3_count += 3;
                        }
                    }
                }
            }
        }

        for (usz subset_number = 0; subset_number < 5; subset_number++) {
            usz omitted = 4 - subset_number;
            usz[4] subset;
            usz count = 0;
            for (usz index = 0; index < 5; index++) {
                if (index != omitted) {
                    subset[count] = index;
                    count += 1;
                }
            }
            for (usz a = 0; a < 4; a++) {
                for (usz b = 0; b < 4; b++) {
                    if (b == a) continue;
                    for (usz c = 0; c < 4; c++) {
                        if (c == a || c == b) continue;
                        for (usz d = 0; d < 4; d++) {
                            if (d == a || d == b || d == c) continue;
                            usz i0 = subset[a];
                            usz i1 = subset[b];
                            usz i2 = subset[c];
                            usz i3 = subset[d];
                            if (p2_count >= 4 && p3_count + 3 <= 6 && p2[i1] == p2[i2] && p2[i1] == p2[i3]) {
                                long x = p2[i0];
                                long y = p2[i1];
                                if (y > x) {
                                    p2_count -= 4;
                                    p3[(usz)p3_count] = x;
                                    p3[(usz)p3_count + 1] = y;
                                    p3[(usz)p3_count + 2] = x + y;
                                    p3_count += 3;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    long[OUTPUT_COUNT] snapshot;
    usz position = 0;
    snapshot[position] = p1_count; position += 1;
    for (usz index = 0; index < 3; index++) { snapshot[position] = p1[index]; position += 1; }
    snapshot[position] = p2_count; position += 1;
    for (usz index = 0; index < 5; index++) { snapshot[position] = p2[index]; position += 1; }
    snapshot[position] = p3_count; position += 1;
    for (usz index = 0; index < 6; index++) { snapshot[position] = p3[index]; position += 1; }
    for (usz index = 0; index < OUTPUT_COUNT; index++) {
        ulong bits = (ulong)snapshot[index];
        for (usz byte = 0; byte < 8; byte++) {
            output[index * 8 + byte] = (char)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)OUTPUT_BYTES;
}
