module single_parameter_truthful_payment;

const int MAX_STEPS = 8;
const int MAX_INPUT = 18;
const int MAX_BID = 16;
const int MAX_OUTPUT = 16;

fn void put_i64(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { out[at + b] = (char)(bits & 255); bits >>= 8; }
}

fn long single_parameter_truthful_payment(long* v, usz n, char* out, usz cap)
    @export("single_parameter_truthful_payment") {
    if (v == null || n < (usz)4 || n > (usz)MAX_INPUT || v[0] < 0 || v[0] > (long)MAX_BID || v[1] < 1 || v[1] > (long)MAX_STEPS) return -1;
    int bid = (int)v[0], k = (int)v[1];
    if (n != (usz)(2 + 2 * k)) return -1;
    for (int i = 0; i < k; i += 1) {
        long point = v[2 + 2 * i], load = v[3 + 2 * i];
        if (point < 0 || point >= MAX_BID || load < 0 || load > MAX_BID) return -1;
        if (i == 0 && point != 0) return -1;
        if (i > 0 && (point <= v[2 + 2 * (i - 1)] || load > v[3 + 2 * (i - 1)])) return -1;
    }
    long allocation = 0;
    if (bid < MAX_BID) for (int i = 0; i < k; i += 1) if (v[2 + 2 * i] <= bid) allocation = v[3 + 2 * i];
    long area = 0;
    for (int i = 0; i < k; i += 1) {
        int start = (int)v[2 + 2 * i];
        int finish = i + 1 < k ? (int)v[2 + 2 * (i + 1)] : MAX_BID;
        int left = start > bid ? start : bid;
        if (finish > left) area += (long)(finish - left) * v[3 + 2 * i];
    }
    long payment = (long)bid * allocation + area;
    if (out == null || cap < (usz)MAX_OUTPUT) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    put_i64(&staged[0], 0, allocation); put_i64(&staged[0], 8, payment);
    for (usz i = 0; i < (usz)MAX_OUTPUT; i += 1) out[i] = staged[i];
    return (long)MAX_OUTPUT;
}
