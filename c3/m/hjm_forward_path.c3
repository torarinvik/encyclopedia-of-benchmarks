module hjm_forward_path;

extern fn double sqrt(double value);

const usz MAX_STEPS = 8;
const usz MAX_FACTORS = 3;
const usz MAX_INPUT = 54;

fn bool integer_in_range(double value, double minimum, double maximum) {
    return value == value && value >= minimum && value <= maximum && (double)(long)value == value;
}

fn long hjm_forward_path(double* input, usz input_length,
                         double* output, usz output_capacity) @export("hjm_forward_path") {
    if (input == null || input_length < 7 || input_length > MAX_INPUT) return -1L;
    double n_value = input[0];
    double factors_value = input[1];
    if (!integer_in_range(n_value, 2.0, 8.0) || !integer_in_range(factors_value, 1.0, 3.0)) return -1L;
    usz steps = (usz)(long)n_value;
    usz factors = (usz)(long)factors_value;
    double years = input[2];
    if (!(years == 1.0 || years == 2.0 || years == 3.0)) return -1L;
    usz expected = 3 + steps + 2 * factors * (steps - 1);
    if (input_length != expected) return -1L;

    double[8] yields = zeroed;
    double[24] vols = zeroed;
    double[21] shocks = zeroed;
    double[8] forwards = zeroed;
    double[21] factor_drifts = zeroed;
    double[7] total_drifts = zeroed;
    double[64] path = zeroed;
    usz cursor = 3;
    for (usz i = 0; i < steps; i++) {
        double value = input[cursor]; cursor++;
        if (!(value >= -0.05 && value <= 0.20)) return -1L;
        yields[i] = value;
    }
    for (usz factor = 0; factor < factors; factor++) {
        for (usz maturity = 0; maturity < steps - 1; maturity++) {
            double value = input[cursor]; cursor++;
            if (!(value >= 0.0 && value <= 0.30)) return -1L;
            vols[factor * 7 + maturity] = value;
        }
    }
    for (usz time = 0; time < steps - 1; time++) {
        for (usz factor = 0; factor < factors; factor++) {
            double value = input[cursor]; cursor++;
            if (!(value >= -3.0 && value <= 3.0)) return -1L;
            shocks[time * 3 + factor] = value;
        }
    }

    double dt = years / (double)steps;
    forwards[0] = yields[0];
    for (usz maturity = 1; maturity < steps; maturity++) {
        forwards[maturity] = (double)(maturity + 1) * yields[maturity]
                           - (double)maturity * yields[maturity - 1];
    }
    for (usz factor = 0; factor < factors; factor++) {
        double first_vol = vols[factor * 7];
        factor_drifts[factor * 7] = 0.5 * dt * first_vol * first_vol;
        for (usz maturity = 1; maturity < steps - 1; maturity++) {
            double drift = 0.0;
            for (usz prior = 0; prior < maturity; prior++) drift -= factor_drifts[factor * 7 + prior];
            double prefix_volatility = 0.0;
            for (usz prior = 0; prior <= maturity; prior++) prefix_volatility += vols[factor * 7 + prior];
            drift += 0.5 * dt * prefix_volatility * prefix_volatility;
            factor_drifts[factor * 7 + maturity] = drift;
        }
    }
    for (usz maturity = 0; maturity < steps - 1; maturity++) {
        for (usz factor = 0; factor < factors; factor++) total_drifts[maturity] += factor_drifts[factor * 7 + maturity];
    }
    for (usz maturity = 0; maturity < steps; maturity++) path[maturity] = forwards[maturity];
    double root_dt = sqrt(dt);
    for (usz time = 1; time < steps; time++) {
        for (usz maturity = 0; maturity < steps - time; maturity++) {
            double total_shock = 0.0;
            for (usz factor = 0; factor < factors; factor++) {
                total_shock += vols[factor * 7 + maturity] * shocks[(time - 1) * 3 + factor];
            }
            path[time * steps + maturity] = path[(time - 1) * steps + maturity + 1]
                + total_drifts[maturity] * dt + root_dt * total_shock;
        }
    }
    usz needed = steps * steps;
    if (output == null || output_capacity < needed) return -2L;
    for (usz i = 0; i < needed; i++) output[i] = path[i];
    return (long)needed;
}
