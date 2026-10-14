// Greedy fractional knapsack with exact fixed-point output.
const MAX_INPUT_VALUES: usize = 258;
const MAX_ITEMS: usize = 128;
const LIMIT: i64 = 1_000_000;
const SCALE: i64 = 1_000_000;

#[derive(Clone, Copy)]
struct Item {
    weight: i64,
    value: i64,
}

#[no_mangle]
pub unsafe extern "C" fn fractional_knapsack_benchmark(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let capacity = *values;
    let item_count_value = *values.add(1);
    if capacity < 0 || capacity > LIMIT || item_count_value < 0 ||
        item_count_value > MAX_ITEMS as i64 { return -1; }
    let item_count = item_count_value as usize;
    if length != 2 + 2 * item_count { return -1; }

    let mut items = [Item { weight: 0, value: 0 }; MAX_ITEMS];
    for i in 0..item_count {
        let weight = *values.add(2 + 2 * i);
        let value = *values.add(3 + 2 * i);
        if weight < 1 || weight > LIMIT || value < 0 || value > LIMIT { return -1; }
        items[i] = Item { weight, value };
    }

    for i in 1..item_count {
        let current = items[i];
        let mut position = i;
        while position > 0 &&
            items[position - 1].value * current.weight <
                current.value * items[position - 1].weight {
            items[position] = items[position - 1];
            position -= 1;
        }
        items[position] = current;
    }

    let mut remaining = capacity;
    let mut scaled_value = 0i64;
    for item in items.iter().take(item_count) {
        if remaining == 0 { break; }
        if remaining >= item.weight {
            scaled_value += item.value * SCALE;
            remaining -= item.weight;
        } else {
            scaled_value += item.value * remaining * SCALE / item.weight;
            break;
        }
    }
    scaled_value
}
