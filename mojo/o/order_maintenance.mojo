from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_ELEMENTS = 64
comptime MAX_OPERATIONS = 128
comptime MAX_INPUT_LENGTH = 387
comptime LABEL_MODULUS = Int64(2_147_483_648)
comptime LABEL_RING = Int64(4_294_967_296)

fn label_width(left: Int64, right: Int64) -> Int64:
    var difference = (right - left) % LABEL_RING
    if difference < 0:
        difference += LABEL_RING
    if difference == 0:
        return LABEL_MODULUS
    if difference > LABEL_MODULUS:
        return difference - LABEL_MODULUS
    return difference

@export("order_maintenance")
fn order_maintenance(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let capacity_value = input[0]
    let operation_value = input[1]
    if capacity_value < 0 or capacity_value > MAX_ELEMENTS or
        operation_value < 0 or operation_value > MAX_OPERATIONS:
        return -1
    let capacity = Int(capacity_value)
    let operation_count = Int(operation_value)
    if length != c_size_t(2 + 3 * operation_count):
        return -1

    var labels = InlineArray[Int64, 65](fill=0)
    var previous = InlineArray[Int, 65](fill=0)
    var following = InlineArray[Int, 65](fill=0)
    var inserted = 0
    var checksum: Int64 = 0
    for operation in range(operation_count):
        let offset = 2 + 3 * operation
        let opcode = input[offset]
        let first = input[offset + 1]
        let second = input[offset + 2]
        if opcode == 0:
            if inserted >= capacity or first < 0 or first > Int64(inserted) or
                second != Int64(inserted + 1):
                return -1
            inserted += 1
            let anchor = Int(first)
            let new_id = inserted
            var successor = following[anchor]
            if label_width(labels[anchor], labels[successor]) <= 1:
                var middle = successor
                var ending = following[middle]
                var required = 3
                while ending != anchor and label_width(labels[anchor], labels[ending]) <=
                    4 * label_width(labels[anchor], labels[middle]):
                    required += 1
                    ending = following[ending]
                    if ending == anchor:
                        break
                    required += 1
                    ending = following[ending]
                    middle = following[middle]
                var interval = LABEL_MODULUS
                if ending != anchor:
                    interval = label_width(labels[anchor], labels[ending])
                let spacing = interval / required
                var value = labels[ending]
                var cursor = ending
                while True:
                    if cursor == 0:
                        value += LABEL_MODULUS
                    if value >= LABEL_RING:
                        value -= LABEL_RING
                    cursor = previous[cursor]
                    if cursor == anchor:
                        break
                    value -= spacing
                    if value < 0:
                        value += LABEL_RING
                    labels[cursor] = value

            successor = following[anchor]
            labels[new_id] = labels[anchor] + label_width(labels[anchor], labels[successor]) / 2
            if labels[new_id] >= LABEL_RING:
                labels[new_id] -= LABEL_RING
            previous[new_id] = anchor
            following[new_id] = successor
            following[anchor] = new_id
            previous[successor] = new_id
        elif opcode == 1:
            if first < 1 or first > Int64(inserted) or second < 1 or second > Int64(inserted):
                return -1
            if labels[Int(first)] < labels[Int(second)]:
                checksum += Int64(operation + 1)
        else:
            return -1
    return checksum
