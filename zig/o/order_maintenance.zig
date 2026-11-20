const MAX_ELEMENTS: i64 = 64;
const MAX_OPERATIONS: i64 = 128;
const MAX_INPUT_LENGTH: usize = 387;
const LABEL_MODULUS: i64 = 2_147_483_648;
const LABEL_RING: i64 = 4_294_967_296;

fn labelWidth(left: i64, right: i64) i64 {
    var difference = right - left;
    if (difference < 0) difference += LABEL_RING;
    if (difference == 0) return LABEL_MODULUS;
    if (difference > LABEL_MODULUS) return difference - LABEL_MODULUS;
    return difference;
}

fn insertAfter(anchor: usize, new_id: usize, labels: *[65]i64,
    previous: *[65]usize, following: *[65]usize) void {
    var successor = following[anchor];
    if (labelWidth(labels[anchor], labels[successor]) <= 1) {
        var middle = successor;
        var ending = following[middle];
        var required: i64 = 3;
        while (ending != anchor and labelWidth(labels[anchor], labels[ending]) <=
            4 * labelWidth(labels[anchor], labels[middle])) {
            required += 1;
            ending = following[ending];
            if (ending == anchor) break;
            required += 1;
            ending = following[ending];
            middle = following[middle];
        }
        const interval = if (ending == anchor) LABEL_MODULUS else
            labelWidth(labels[anchor], labels[ending]);
        const spacing = interval / required;
        var value = labels[ending];
        var cursor = ending;
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
    labels[new_id] = labels[anchor] + labelWidth(labels[anchor], labels[successor]) / 2;
    if (labels[new_id] >= LABEL_RING) labels[new_id] -= LABEL_RING;
    previous[new_id] = anchor;
    following[new_id] = successor;
    following[anchor] = new_id;
    previous[successor] = new_id;
}

export fn order_maintenance(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const capacity_value = input[0];
    const operation_value = input[1];
    if (capacity_value < 0 or capacity_value > MAX_ELEMENTS or operation_value < 0 or
        operation_value > MAX_OPERATIONS) return -1;
    const capacity: usize = @intCast(capacity_value);
    const operation_count: usize = @intCast(operation_value);
    if (length != 2 + 3 * operation_count) return -1;

    var labels: [65]i64 = @splat(0);
    var previous: [65]usize = @splat(0);
    var following: [65]usize = @splat(0);
    var inserted: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const offset = 2 + 3 * operation;
        const opcode = input[offset];
        const first = input[offset + 1];
        const second = input[offset + 2];
        if (opcode == 0) {
            if (inserted >= capacity or first < 0 or first > @as(i64, @intCast(inserted)) or
                second != @as(i64, @intCast(inserted + 1))) return -1;
            inserted += 1;
            insertAfter(@intCast(first), inserted, &labels, &previous, &following);
        } else if (opcode == 1) {
            if (first < 1 or first > @as(i64, @intCast(inserted)) or second < 1 or
                second > @as(i64, @intCast(inserted))) return -1;
            if (labels[@intCast(first)] < labels[@intCast(second)])
                checksum += @as(i64, @intCast(operation + 1));
        } else return -1;
    }
    return checksum;
}
