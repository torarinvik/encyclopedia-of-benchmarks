module car_pool;

fn long car_pool(long* input, usz length) @export("car_pool") {
    if (input == null || length < 2 || length > 194) return -1;
    if (input[0] < 0 || input[0] > 1000 || input[1] < 0 || input[1] > 64) return -1;
    long capacity = input[0];
    usz trip_count = (usz)input[1];
    if (length != 2 + 3 * trip_count) return -1;

    int[1001] events;
    for (usz position = 0; position < 1001; position++) events[position] = 0;
    for (usz trip = 0; trip < trip_count; trip++) {
        usz offset = 2 + 3 * trip;
        long passengers = input[offset];
        long origin = input[offset + 1];
        long destination = input[offset + 2];
        if (passengers < 1 || passengers > 1000 || origin < 0 || origin >= destination || destination > 1000) return -1;
        events[(usz)origin] += (int)passengers;
        events[(usz)destination] -= (int)passengers;
    }

    int occupants = 0;
    for (usz position = 0; position < 1000; position++) {
        occupants += events[position];
        if ((long)occupants > capacity) return 0;
    }
    return 1;
}
