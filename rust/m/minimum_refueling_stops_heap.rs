/// Greedy minimum refueling stops using Rust's max-heap.
use std::collections::BinaryHeap;

#[no_mangle]
pub extern "C" fn minimum_refueling_stops_heap(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=20).contains(&length) { return -2; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let target = values[0];
    let start_fuel = values[1];
    let count_value = values[2];
    if !(1..=2000).contains(&target) || !(0..=2000).contains(&start_fuel)
        || !(0..=8).contains(&count_value) { return -2; }
    let count = count_value as usize;
    if length != 3 + 2 * count { return -2; }
    let mut previous = 0i64;
    for station in 0..count {
        let position = values[3 + 2 * station];
        let fuel = values[4 + 2 * station];
        if position <= previous || position >= target || !(1..=2000).contains(&fuel) { return -2; }
        previous = position;
    }

    let mut heap = BinaryHeap::with_capacity(count);
    let mut next_station = 0usize;
    let mut reach = start_fuel;
    let mut stops = 0i64;
    while reach < target {
        while next_station < count && values[3 + 2 * next_station] <= reach {
            heap.push(values[4 + 2 * next_station]);
            next_station += 1;
        }
        let Some(fuel) = heap.pop() else { return -1; };
        reach += fuel;
        stops += 1;
    }
    stops
}
