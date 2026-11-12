module metropolis_mcmc;

extern fn double trunc(double value);
extern fn double exp(double value);

const usz MAX_STATES = 8;
const usz MAX_STEPS = 64;
const usz MAX_INPUT = 140;

fn bool bounded_integer(double value, double minimum, double maximum) {
    return value == value && trunc(value) == value && value >= minimum && value <= maximum;
}

fn long metropolis_mcmc(double* input, usz length, double* output, usz capacity)
    @export("metropolis_mcmc") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    if (!bounded_integer(input[0], 1.0, (double)MAX_STATES) ||
        !bounded_integer(input[1], 0.0, (double)MAX_STEPS)) return -1;
    usz states = (usz)input[0];
    usz steps = (usz)input[1];
    if (!bounded_integer(input[2], 0.0, (double)(states - 1)) ||
        input[3] != input[3] || input[3] < 0.001 || input[3] > 1000.0 ||
        length != 4 + states + 2 * steps) return -1;
    for (usz state = 0; state < states; state += 1) {
        double energy = input[4 + state];
        if (energy != energy || energy < -1000000.0 || energy > 1000000.0) return -1;
    }
    usz proposal_start = 4 + states;
    usz uniform_start = proposal_start + steps;
    for (usz step = 0; step < steps; step += 1) {
        if (!bounded_integer(input[proposal_start + step], 0.0, (double)(states - 1))) return -1;
        double uniform = input[uniform_start + step];
        if (uniform != uniform || uniform < 0.0 || uniform >= 1.0) return -1;
    }
    if (output == null || capacity < steps + 1) return -2;

    usz current = (usz)input[2];
    output[0] = (double)current;
    for (usz step = 0; step < steps; step += 1) {
        usz proposal = (usz)input[proposal_start + step];
        double delta = (input[4 + proposal] - input[4 + current]) / input[3];
        if (delta <= 0.0) current = proposal;
        else if (input[uniform_start + step] < exp(-delta)) current = proposal;
        output[step + 1] = (double)current;
    }
    return (long)(steps + 1);
}
