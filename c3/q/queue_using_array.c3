module queue_using_array;

const usz MAX_Q = 512, MAX_INPUT = 1025;
const long MAX_Q_VALUE = 512;
const long CHECKSUM_OFFSET = 128;

fn long queue_using_array(long* packed, usz length) @export("queue_using_array") {
    if (packed == null || length < 1 || length > MAX_INPUT) return -1;
    long qv = packed[0];
    if (qv < 0 || qv > MAX_Q_VALUE || length != 1 + (usz)qv * 2) return -1;
    usz q = (usz)qv;
    for (usz i = 0; i < q; i++) {
        long op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 0) { if (value < -128 || value > 127) return -1; }
        else if (op == 1) { if (value != 0) return -1; }
        else return -1;
    }
    short[10] values = zeroed;
    long front = -1, rear = -1;
    long checksum = 0, ordinal = 0;
    for (usz i = 0; i < q; i++) {
        long op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 0) {
            if (rear == 9) continue;
            if (front == -1 && rear == -1) { front = 0; rear = 0; values[0] = (short)value; }
            else if (rear < 10) { rear++; values[(usz)rear] = (short)value; }
        } else {
            long dequeued = 0;
            if (front != -1) {
                if (front == rear) { dequeued = (long)values[(usz)front]; front = -1; rear = -1; }
                else { dequeued = (long)values[(usz)front]; front++; }
            }
            ordinal++;
            checksum += ordinal * (dequeued + CHECKSUM_OFFSET);
        }
    }
    return checksum;
}
