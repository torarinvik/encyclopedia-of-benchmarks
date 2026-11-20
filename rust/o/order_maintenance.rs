const MAX_ELEMENTS: i64 = 64;
const MAX_OPERATIONS: i64 = 128;
const MAX_INPUT_LENGTH: usize = 387;
const LABEL_MODULUS: i64 = 2_147_483_648;
const LABEL_RING: i64 = 4_294_967_296;

fn label_width(left: i64, right: i64) -> i64 {
    let mut difference = right - left;
    if difference < 0 { difference += LABEL_RING; }
    if difference == 0 { LABEL_MODULUS }
    else if difference > LABEL_MODULUS { difference - LABEL_MODULUS }
    else { difference }
}

fn insert_after(anchor: usize, new_id: usize, labels: &mut [i64; 65],
                previous: &mut [usize; 65], following: &mut [usize; 65]) {
    let mut successor = following[anchor];
    if label_width(labels[anchor], labels[successor]) <= 1 {
        let mut middle = successor;
        let mut end = following[middle];
        let mut required = 3_i64;
        while end != anchor && label_width(labels[anchor], labels[end]) <=
            4 * label_width(labels[anchor], labels[middle]) {
            required += 1;
            end = following[end];
            if end == anchor { break; }
            required += 1;
            end = following[end];
            middle = following[middle];
        }
        let interval = if end == anchor { LABEL_MODULUS }
            else { label_width(labels[anchor], labels[end]) };
        let spacing = interval / required;
        let mut value = labels[end];
        let mut cursor = end;
        loop {
            if cursor == 0 {
                value += LABEL_MODULUS;
                if value >= LABEL_RING { value -= LABEL_RING; }
            }
            cursor = previous[cursor];
            if cursor == anchor { break; }
            value -= spacing;
            if value < 0 { value += LABEL_RING; }
            labels[cursor] = value;
        }
    }
    successor = following[anchor];
    labels[new_id] = labels[anchor] + label_width(labels[anchor], labels[successor]) / 2;
    if labels[new_id] >= LABEL_RING { labels[new_id] -= LABEL_RING; }
    previous[new_id] = anchor;
    following[new_id] = successor;
    following[anchor] = new_id;
    previous[successor] = new_id;
}

#[no_mangle]
pub unsafe extern "C" fn order_maintenance(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (capacity_value, operation_value) = (values[0], values[1]);
    if !(0..=MAX_ELEMENTS).contains(&capacity_value)
        || !(0..=MAX_OPERATIONS).contains(&operation_value) { return -1; }
    let capacity = capacity_value as usize;
    let operation_count = operation_value as usize;
    if length != 2 + 3 * operation_count { return -1; }

    let mut labels = [0_i64; 65];
    let mut previous = [0_usize; 65];
    let mut following = [0_usize; 65];
    let mut inserted = 0_usize;
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let offset = 2 + 3 * operation;
        let (opcode, first, second) = (values[offset], values[offset + 1], values[offset + 2]);
        if opcode == 0 {
            if inserted >= capacity || first < 0 || first as usize > inserted
                || second != inserted as i64 + 1 { return -1; }
            inserted += 1;
            insert_after(first as usize, inserted, &mut labels, &mut previous, &mut following);
        } else if opcode == 1 {
            if first < 1 || first as usize > inserted || second < 1 || second as usize > inserted {
                return -1;
            }
            if labels[first as usize] < labels[second as usize] { checksum += (operation + 1) as i64; }
        } else { return -1; }
    }
    checksum
}
