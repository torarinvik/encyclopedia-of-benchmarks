module order_maintenance;

const int MAX_ELEMENTS = 64;
const int MAX_OPERATIONS = 128;
const usz MAX_INPUT_LENGTH = 387;
const long LABEL_MODULUS = 2147483648;
const long LABEL_RING = 4294967296;

fn long label_width(long left, long right) {
    long difference = right - left;
    if (difference < 0) difference += LABEL_RING;
    if (difference == 0) return LABEL_MODULUS;
    return difference > LABEL_MODULUS ? difference - LABEL_MODULUS : difference;
}

fn void insert_after(int anchor, int new_id, long* labels, int* previous, int* following) {
    int successor = following[anchor];
    if (label_width(labels[anchor], labels[successor]) <= 1) {
        int middle = successor;
        int end = following[middle];
        long required = 3;
        while (end != anchor && label_width(labels[anchor], labels[end]) <=
               4 * label_width(labels[anchor], labels[middle])) {
            required += 1;
            end = following[end];
            if (end == anchor) break;
            required += 1;
            end = following[end];
            middle = following[middle];
        }
        long interval = end == anchor ? LABEL_MODULUS : label_width(labels[anchor], labels[end]);
        long spacing = interval / required;
        long value = labels[end];
        int cursor = end;
        while (true) {
            if (cursor == 0) {
                value += LABEL_MODULUS;
                if (value >= LABEL_RING) value -= LABEL_RING;
            }
            cursor = previous[cursor];
            if (cursor == anchor) break;
            value -= spacing;
            if (value < 0) value += LABEL_RING;
            labels[cursor] = value;
        }
    }
    successor = following[anchor];
    labels[new_id] = labels[anchor] + label_width(labels[anchor], labels[successor]) / 2;
    if (labels[new_id] >= LABEL_RING) labels[new_id] -= LABEL_RING;
    previous[new_id] = anchor;
    following[new_id] = successor;
    following[anchor] = new_id;
    previous[successor] = new_id;
}

fn long order_maintenance(long* input, usz length) @export("order_maintenance") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long capacity_value = input[0], operation_value = input[1];
    if (capacity_value < 0 || capacity_value > MAX_ELEMENTS || operation_value < 0 ||
        operation_value > MAX_OPERATIONS || length != 2 + 3 * (usz)operation_value) return -1;
    int capacity = (int)capacity_value, operation_count = (int)operation_value;

    long[MAX_ELEMENTS + 1] labels = zeroed;
    int[MAX_ELEMENTS + 1] previous = zeroed;
    int[MAX_ELEMENTS + 1] following = zeroed;
    int inserted = 0;
    long checksum = 0;
    for (int operation = 0; operation < operation_count; operation += 1) {
        usz offset = 2 + 3 * (usz)operation;
        long opcode = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (opcode == 0) {
            if (inserted >= capacity || first < 0 || first > (long)inserted ||
                second != (long)inserted + 1)
                return -1;
            inserted += 1;
            insert_after((int)first, inserted, labels, previous, following);
        } else if (opcode == 1) {
            if (first < 1 || first > (long)inserted || second < 1 ||
                second > (long)inserted) return -1;
            if (labels[(usz)first] < labels[(usz)second]) checksum += (long)operation + 1;
        } else return -1;
    }
    return checksum;
}
