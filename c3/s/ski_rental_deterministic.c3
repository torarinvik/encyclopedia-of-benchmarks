module ski_rental_deterministic;

const usz MAX_INPUT = 4;
const usz MAX_TRIPS = 32;

long ski_rental_deterministic(long* input, usz length, char* output, usz capacity)
        @export("ski_rental_deterministic") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long rent = input[0], purchase = input[1], trips = input[2];
    if (length != 3 || rent < 1 || rent > 32 || purchase < 1 || purchase > 64 || trips < 0 || trips > (long)MAX_TRIPS) return -1;
    usz count = (usz)trips;
    if (output == null || capacity < count) return -2;
    char[MAX_TRIPS] actions = zeroed;
    long threshold = purchase / rent;
    for (usz trip = 0; trip < count; trip++) {
        if ((long)trip < threshold) actions[trip] = 0;
        else if ((long)trip == threshold) actions[trip] = 1;
        else actions[trip] = 2;
    }
    for (usz trip = 0; trip < count; trip++) output[trip] = actions[trip];
    return (long)count;
}
