module traveling_salesman_bitmask;

const usz MAX_CITIES = 10;
const usz MAX_MASKS = 1024;
const usz MAX_STATES = 10240;
const usz MAX_INPUT_VALUES = 102;

fn long solve(usz position, usz mask, usz city_count, long* distances,
              long* memo, bool* seen) {
    usz all_visited = ((usz)1 << city_count) - 1;
    if (mask == all_visited) return distances[position * city_count];
    usz state = position * MAX_MASKS + mask;
    if (seen[state]) return memo[state];

    long best = 10001L;
    seen[state] = true;
    for (usz city = 0; city < city_count; city++) {
        usz bit = (usz)1 << city;
        if ((mask & bit) == 0) {
            long cost = distances[position * city_count + city] +
                solve(city, mask | bit, city_count, distances, memo, seen);
            if (cost < best) best = cost;
        }
    }
    memo[state] = best;
    return best;
}

fn long traveling_salesman_bitmask(long* input, usz length) @export("traveling_salesman_bitmask") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1L;
    long city_count_value = input[0];
    if (city_count_value < 2L || city_count_value > (long)MAX_CITIES) return -1L;
    usz city_count = (usz)city_count_value;
    if (length != 1 + city_count * city_count) return -1L;

    long[MAX_CITIES * MAX_CITIES] distances = zeroed;
    for (usz index = 0; index < city_count * city_count; index++) {
        long distance = input[1 + index];
        if (distance < 0L || distance > 1000L) return -1L;
        if (index / city_count == index % city_count && distance != 0L) return -1L;
        distances[index] = distance;
    }

    long[MAX_STATES] memo = zeroed;
    bool[MAX_STATES] seen = zeroed;
    return solve(0, 1, city_count, &distances[0], &memo[0], &seen[0]);
}
