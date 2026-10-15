module distance_between_bus_stops;

// Sum both circular routes and return the shorter one.
fn long distance_between_bus_stops(long* input, usz length) @export("distance_between_bus_stops")
{
    if (length < 3 || length > 66) return -1;
    usz stop_count = length - 2;
    long start = input[0];
    long destination = input[1];
    if (start < 0 || destination < 0 ||
        start >= (long)stop_count || destination >= (long)stop_count) return -1;

    usz low = (usz)(start < destination ? start : destination);
    usz high = (usz)(start < destination ? destination : start);
    long total = 0;
    long direct = 0;
    for (usz index = 0; index < stop_count; index++) {
        long distance = input[index + 2];
        if (distance < 0 || distance > 1000000) return -1;
        total += distance;
        if (index >= low && index < high) direct += distance;
    }
    long other = total - direct;
    return direct < other ? direct : other;
}
