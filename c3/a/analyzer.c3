module analyzer;
const usz MAX_EVENTS = 64;
const long MAX_EPOCH = 15;
const long MAX_ADDRESS = 255;

long analyzer(long* input, usz length) @export("analyzer") {
    if (input == null || length < 1 || length > 194) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > MAX_EVENTS.long()) return -1;
    usz count = count_value.usize();
    if (length != 1 + 3 * count) return -1;
    long[256] latest_writer;
    for (usz address = 0; address < 256; address++) latest_writer[address] = -1;
    long conflicts = 0, previous_epoch = 0;
    for (usz event = 0; event < count; event++) {
        usz base = 1 + 3 * event;
        long epoch = input[base], opcode = input[base + 1], address_value = input[base + 2];
        if (epoch < previous_epoch || epoch < 0 || epoch > MAX_EPOCH
                || (opcode != 0 && opcode != 1) || address_value < 0 || address_value > MAX_ADDRESS) return -1;
        previous_epoch = epoch;
        usz address = address_value.usize();
        if (opcode == 0) latest_writer[address] = event.long();
        else {
            for (usz prior = 0; prior < event; prior++) {
                usz prior_base = 1 + 3 * prior;
                if (input[prior_base] < epoch && input[prior_base + 1] == 0
                        && input[prior_base + 2] == address_value
                        && latest_writer[address] == prior.long()) conflicts++;
            }
        }
    }
    conflicts
}
