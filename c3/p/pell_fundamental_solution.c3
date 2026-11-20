module pell_fundamental_solution;

fn long pell_fundamental_solution(long* input, usz length)
    @export("pell_fundamental_solution") {
    if (input == null || length != 1) return -1;

    long d_value = input[0];
    if (d_value < 2 || d_value > 31) return -1;

    long a0 = 1;
    while ((a0 + 1) * (a0 + 1) <= d_value) a0 += 1;
    if (a0 * a0 == d_value) return -1;

    long m = 0;
    long denominator = 1;
    long coefficient = a0;
    long p_previous_previous = 0;
    long p_previous = 1;
    long q_previous_previous = 1;
    long q_previous = 0;

    while (true) {
        long p = coefficient * p_previous + p_previous_previous;
        long q = coefficient * q_previous + q_previous_previous;
        if (p * p - d_value * q * q == 1) {
            return p * 4294967296L + q;
        }

        p_previous_previous = p_previous;
        p_previous = p;
        q_previous_previous = q_previous;
        q_previous = q;

        long next_m = denominator * coefficient - m;
        long next_denominator = (d_value - next_m * next_m) / denominator;
        long next_coefficient = (a0 + next_m) / next_denominator;
        m = next_m;
        denominator = next_denominator;
        coefficient = next_coefficient;
    }
}
