module greedy_item_selection_by_value;

const long MAX_ITEMS = 8;

fn long greedy_item_selection_by_value(long* values, usz length) @export("greedy_item_selection_by_value") {
    if (values == null || length < 2 || length > 18) return -1;
    long capacity = values[0], count_value = values[1];
    if (capacity < 0 || capacity > 1000000 || count_value < 0 || count_value > MAX_ITEMS || length != 2 + 2 * (usz)count_value) return -1;
    int count = (int)count_value;
    long[MAX_ITEMS] item_values = {}, weights = {};
    int[MAX_ITEMS] order = {};
    for (int index = 0; index < count; index++) {
        item_values[index] = values[2 + (usz)index];
        weights[index] = values[2 + (usz)count + (usz)index];
        if (item_values[index] < 0 || item_values[index] > 1000000 || weights[index] < 1 || weights[index] > 1000000) return -1;
        order[index] = index;
    }
    for (int index = 1; index < count; index++) {
        int current = order[index];
        int position = index;
        while (position > 0 && item_values[order[position - 1]] < item_values[current]) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = current;
    }
    long total_weight = 0, total_value = 0, sequence = 0;
    int selected = 0;
    for (int index = 0; index < count; index++) {
        int item = order[index];
        if (total_weight + weights[item] <= capacity) {
            sequence |= (long)(item + 1) << (4 * selected);
            selected++;
            total_weight += weights[item];
            total_value += item_values[item];
        }
    }
    return (total_value << 36) | ((long)selected << 32) | sequence;
}
