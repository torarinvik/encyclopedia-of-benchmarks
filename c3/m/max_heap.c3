module max_heap;

const MAX_OPERATIONS = 512;
const MAX_INSERTIONS = 256;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long max_heap(long* input, usz length, char* output, usz capacity) @export("max_heap") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    usz operations = (usz)input[0];
    if (length != 1 + operations * 2) return -1;
    usz inserts = 0, words = 0;
    for (usz i = 0; i < operations; i++) {
        long op = input[1 + 2 * i], value = input[2 + 2 * i];
        if (op < 0 || op > 2) return -1;
        if (op == 0) { inserts++; if (inserts > MAX_INSERTIONS || value < -2147483648 || value > 2147483647) return -1; }
        else { if (value != 0) return -1; words++; }
    }
    if (capacity < words * 8 || (words > 0 && output == null)) return -2;
    long[MAX_INSERTIONS] heap;
    usz size = 0, out_index = 0;
    for (usz i = 0; i < operations; i++) {
        long op = input[1 + 2 * i], value = input[2 + 2 * i];
        if (op == 0) {
            usz at = size; heap[at] = value; size++;
            while (at > 0) { usz parent = (at - 1) / 2; if (heap[parent] >= heap[at]) break; long t = heap[parent]; heap[parent] = heap[at]; heap[at] = t; at = parent; }
            continue;
        }
        long result = -9223372036854775807L - 1;
        if (size > 0) {
            result = heap[0];
            if (op == 2) { size--; heap[0] = heap[size]; usz at = 0;
                while (at < size / 2) { usz child = at * 2 + 1; if (child + 1 < size && heap[child + 1] > heap[child]) child++;
                    if (heap[at] >= heap[child]) break; long t = heap[at]; heap[at] = heap[child]; heap[child] = t; at = child; }
            }
        }
        store_i64_le(output, out_index * 8, result); out_index++;
    }
    return (long)words;
}
