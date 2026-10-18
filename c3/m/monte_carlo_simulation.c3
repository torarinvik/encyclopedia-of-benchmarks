module monte_carlo_simulation;
import "math";

const usz MAX_SIMULATIONS = 32;
const usz MAX_PARSEABLE_INPUT_LENGTH = 520;

fn bool finite_value(double value) {
    return value == value && value >= -1.7976931348623157e308 &&
           value <= 1.7976931348623157e308;
}

fn bool allowed_maturity(double value) {
    return value == 0.25 || value == 0.5 || value == 1.0 || value == 2.0;
}

fn bool allowed_step_count(double value) {
    return value == 1.0 || value == 2.0 || value == 4.0 || value == 8.0 || value == 16.0;
}

fn long monte_carlo_simulation(double* values, usz length, double* output, usz output_capacity)
    @export("monte_carlo_simulation") {
    if (values == null || length < 7 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < length; index++)
        if (!finite_value(values[index])) return -1L;

    double s0 = values[0], strike = values[1], rate = values[2], volatility = values[3];
    double maturity = values[4], step_value = values[5], simulation_value = values[6];
    if (s0 < 1.0 || s0 > 1000.0 || strike < 0.0 || strike > 2000.0 ||
        rate < -0.25 || rate > 0.25 || volatility < 0.0 || volatility > 0.5 ||
        !allowed_maturity(maturity) || !allowed_step_count(step_value) ||
        simulation_value < 1.0 || simulation_value > (double)MAX_SIMULATIONS ||
        (double)(long)simulation_value != simulation_value) return -1L;

    usz steps = (usz)step_value, simulations = (usz)simulation_value;
    if (length != 7 + steps * simulations) return -1L;
    for (usz index = 7; index < length; index++)
        if (values[index] < -3.0 || values[index] > 3.0) return -1L;

    double dt = maturity / (double)steps;
    double sqrt_dt = math.sqrt(dt);
    double drift_rate = rate - 0.5 * (volatility * volatility);
    double drift = drift_rate * maturity;
    double payoffs[MAX_SIMULATIONS] = {0.0};
    for (usz simulation = 0; simulation < simulations; simulation++) {
        double brownian = 0.0;
        usz offset = 7 + simulation * steps;
        for (usz step = 0; step < steps; step++)
            brownian += sqrt_dt * values[offset + step];
        double exponent = drift + volatility * brownian;
        double terminal_price = s0 * math.exp(exponent);
        double difference = terminal_price - strike;
        payoffs[simulation] = difference > 0.0 ? difference : 0.0;
    }

    double total = 0.0;
    for (usz simulation = 0; simulation < simulations; simulation++)
        total += payoffs[simulation];
    double option_price = (total / (double)simulations) * math.exp(-rate * maturity);
    if (!finite_value(option_price)) return -1L;
    if (output == null || output_capacity < 1) return -2L;
    output[0] = option_price;
    return 1L;
}
