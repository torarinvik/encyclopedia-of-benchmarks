module branch_bound_knapsack;

const usz MAX_ITEMS = 8;
const usz MAX_NODES = 511;

struct SearchNode {
    int level;
    int weight;
    int value;
    int mask;
}

fn double upper_bound(int* weights, int* item_values, int count, int capacity,
                      int level, int weight, int value) {
    int available = capacity - weight;
    double bound = value;
    int next = level + 1;
    while (available > 0 && next < count) {
        if (weights[next] <= available) {
            bound += item_values[next];
            available -= weights[next];
        } else {
            bound += ((double)item_values[next] / (double)weights[next]) * (double)available;
            available = 0;
        }
        next++;
    }
    return bound;
}

fn long branch_and_bound_knapsack_solver(long* input, usz length,
                                          char* output, usz output_capacity)
    @export("branch_and_bound_knapsack_solver")
{
    if (input == null || length < 2 || length > 18) return -1;
    if (input[0] < 0 || input[0] > 8 || input[1] < 0 || input[1] > 8000) return -1;
    int count = (int)input[0];
    int capacity = (int)input[1];
    if (length != 2 + 2 * (usz)count) return -1;

    int[MAX_ITEMS] weights;
    int[MAX_ITEMS] item_values;
    int[MAX_ITEMS] item_ids;
    for (int index = 0; index < count; index++) {
        long weight = input[2 + 2 * index];
        long value = input[3 + 2 * index];
        if (weight < 1 || weight > 1000 || value < 1 || value > 1000) return -1;
        int position = index;
        while (position > 0 && value * (long)weights[position - 1] > (long)item_values[position - 1] * weight) {
            weights[position] = weights[position - 1];
            item_values[position] = item_values[position - 1];
            item_ids[position] = item_ids[position - 1];
            position--;
        }
        weights[position] = (int)weight;
        item_values[position] = (int)value;
        item_ids[position] = index;
    }

    SearchNode[MAX_NODES] queue;
    usz head = 0;
    usz tail = 1;
    queue[0] = { .level = -1, .weight = 0, .value = 0, .mask = 0 };
    int best_value = 0;
    int best_mask = 0;
    while (head < tail) {
        SearchNode parent = queue[head];
        head++;
        if (parent.level == count - 1) continue;
        int next = parent.level + 1;
        SearchNode left = { .level = next, .weight = parent.weight + weights[next],
            .value = parent.value + item_values[next], .mask = parent.mask | (1 << next) };
        SearchNode right = { .level = next, .weight = parent.weight,
            .value = parent.value, .mask = parent.mask };
        if (left.weight <= capacity && left.value > best_value) {
            best_value = left.value;
            best_mask = left.mask;
        }
        if (upper_bound(&weights[0], &item_values[0], count, capacity,
                        left.level, left.weight, left.value) > (double)best_value
            && left.weight < capacity) {
            queue[tail] = left;
            tail++;
        }
        if (upper_bound(&weights[0], &item_values[0], count, capacity,
                        right.level, right.weight, right.value) > (double)best_value) {
            queue[tail] = right;
            tail++;
        }
    }

    char[MAX_ITEMS] selected;
    usz selected_count = 0;
    int level = count - 1;
    while (level >= 0) {
        if ((best_mask & (1 << level)) != 0) {
            selected[selected_count] = (char)item_ids[level];
            selected_count++;
        }
        level--;
    }
    if (selected_count > output_capacity || (selected_count != 0 && output == null)) return -2;
    for (usz index = 0; index < selected_count; index++) output[index] = selected[index];
    return (long)selected_count;
}
