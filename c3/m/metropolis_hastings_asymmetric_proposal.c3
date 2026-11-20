module metropolis_hastings_asymmetric_proposal;

const usz MAX_STATES = 8;
const usz MAX_STEPS = 64;
const usz MAX_INPUT = 267;
const usz MAX_OUTPUT = 65;

fn long metropolis_hastings_asymmetric_proposal(long* input, usz length, char* output, usz capacity)
    @export("metropolis_hastings_asymmetric_proposal") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0];
    long steps64 = input[1];
    long initial64 = input[2];
    if (n64 < 2 || n64 > (long)MAX_STATES || steps64 < 0 || steps64 > (long)MAX_STEPS ||
        initial64 < 0 || initial64 >= n64) return -1;
    usz n = (usz)n64;
    usz steps = (usz)steps64;
    usz weights_start = 3;
    usz matrix_start = weights_start + n;
    usz proposals_start = matrix_start + n*n;
    usz draws_start = proposals_start + steps;
    if (length != draws_start + 2*steps) return -1;
    for (usz state = 0; state < n; state++) {
        long weight = input[weights_start + state];
        if (weight < 1 || weight > 1024) return -1;
    }
    for (usz row = 0; row < n; row++) {
        long row_sum = 0;
        for (usz column = 0; column < n; column++) {
            long q = input[matrix_start + row*n + column];
            if (q < 0 || q > 1024) return -1;
            row_sum += q;
        }
        if (row_sum != 1024) return -1;
    }

    char[MAX_OUTPUT] staged;
    usz current = (usz)initial64;
    staged[0] = (char)current;
    for (usz step = 0; step < steps; step++) {
        long proposal64 = input[proposals_start + step];
        long draw_num = input[draws_start + 2*step];
        long draw_den = input[draws_start + 2*step + 1];
        if (proposal64 < 0 || proposal64 >= n64 || draw_den < 1 || draw_den > 1024 ||
            draw_num < 0 || draw_num >= draw_den) return -1;
        usz proposal = (usz)proposal64;
        long forward = input[matrix_start + current*n + proposal];
        if (forward == 0) return -1;
        long reverse = input[matrix_start + proposal*n + current];
        long numerator = input[weights_start + proposal] * reverse;
        long denominator = input[weights_start + current] * forward;
        if (numerator >= denominator || draw_num*denominator < draw_den*numerator) current = proposal;
        staged[step + 1] = (char)current;
    }

    usz needed = steps + 1;
    if (output == null || capacity < needed) return -2;
    for (usz index = 0; index < needed; index++) output[index] = staged[index];
    return (long)needed;
}
