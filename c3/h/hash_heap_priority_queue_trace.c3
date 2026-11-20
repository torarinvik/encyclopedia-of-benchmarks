module hash_heap_priority_queue_trace;

struct HhItem { u8 key; u8 insertion; }

fn bool hh_before(HhItem a, HhItem b) {
    return a.key < b.key || (a.key == b.key && a.insertion < b.insertion);
}

fn void hh_swap(HhItem* heap, usz a, usz b) {
    HhItem temporary = heap[a];
    heap[a] = heap[b];
    heap[b] = temporary;
}

fn void hh_push(HhItem* heaps, usz* sizes, usz bucket, HhItem item) {
    usz base = bucket * 64;
    usz child = sizes[bucket];
    sizes[bucket] += 1;
    heaps[base + child] = item;
    while (child > 0) {
        usz parent = (child - 1) / 2;
        if (!hh_before(heaps[base + child], heaps[base + parent])) break;
        hh_swap(&heaps[base], child, parent);
        child = parent;
    }
}

fn void hh_pop(HhItem* heaps, usz* sizes, usz bucket) {
    sizes[bucket] -= 1;
    usz last = sizes[bucket];
    if (last == 0) return;
    usz base = bucket * 64;
    heaps[base] = heaps[base + last];
    usz parent = 0;
    while (true) {
        usz left = parent * 2 + 1;
        if (left >= last) break;
        usz child = left;
        usz right = left + 1;
        if (right < last && hh_before(heaps[base + right], heaps[base + left])) child = right;
        if (!hh_before(heaps[base + child], heaps[base + parent])) break;
        hh_swap(&heaps[base], child, parent);
        parent = child;
    }
}

fn void hh_write(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long hash_heap_priority_queue_trace(long* input, usz length, char* output, usz capacity)
    @export("hash_heap_priority_queue_trace") {
    if (input == null || length < 3 || length > 132) return -1;
    long universe_value = input[0];
    long bucket_value = input[1];
    long count_value = input[2];
    if (universe_value < 1 || universe_value > 128 || bucket_value < 1 || bucket_value > 8 ||
        bucket_value > universe_value || count_value < 0 || count_value > 64) return -1;
    usz universe = (usz)universe_value;
    usz bucket_count = (usz)bucket_value;
    usz count = (usz)count_value;
    if (length != 3 + 2 * count) return -1;

    u8[64] operations = zeroed;
    u8[64] arguments = zeroed;
    for (usz op = 0; op < count; op += 1) {
        long opcode = input[3 + 2 * op];
        long argument = input[4 + 2 * op];
        if (opcode == 0) {
            if (argument < 0 || argument >= universe_value) return -1;
        } else if (opcode == 1 || opcode == 2) {
            if (argument != 0) return -1;
        } else return -1;
        operations[op] = (u8)opcode;
        arguments[op] = (u8)argument;
    }

    HhItem[512] heaps = zeroed;
    usz[8] sizes = zeroed;
    char[520] staged = zeroed;
    hh_write(&staged[0], 0, (long)count);
    for (usz op = 0; op < count; op += 1) {
        usz output_offset = (op + 1) * 8;
        if (operations[op] == 0) {
            usz bucket = ((usz)arguments[op] * bucket_count) / universe;
            HhItem item = {.key = arguments[op], .insertion = (u8)op};
            hh_push(&heaps[0], &sizes[0], bucket, item);
            hh_write(&staged[0], output_offset, -2);
            continue;
        }
        usz bucket = 0;
        while (bucket < bucket_count && sizes[bucket] == 0) bucket += 1;
        if (bucket == bucket_count) {
            hh_write(&staged[0], output_offset, -1);
            continue;
        }
        HhItem minimum = heaps[bucket * 64];
        long packed = ((long)minimum.insertion << 8) | (long)minimum.key;
        hh_write(&staged[0], output_offset, packed);
        if (operations[op] == 2) hh_pop(&heaps[0], &sizes[0], bucket);
    }

    usz required = (count + 1) * 8;
    if (output == null || capacity < required) return -2;
    for (usz byte = 0; byte < required; byte += 1) output[byte] = staged[byte];
    return (long)required;
}
