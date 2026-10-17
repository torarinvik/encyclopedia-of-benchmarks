module relativity;

extern fn double sqrt(double value);

const double SPEED_OF_LIGHT = 299792458.0;
const long SPEED_OF_LIGHT_MILLI = 299792458000;
const long MAX_LENGTH_TIME_MILLI = 1000000;
const usz MAX_INPUT_LENGTH = 4;
const double INVALID_RESULT = -1.0e300;

fn double lorentz_gamma(double velocity) {
    return 1.0 / sqrt(1.0 - velocity * velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT));
}

fn double relativity(long* input, usz length) @export("relativity") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long operation = input[0], arg1_milli = input[1], arg2_milli = input[2];
    if (length != 3) return INVALID_RESULT;

    if (operation == 0) {
        if (arg2_milli != 0 || arg1_milli <= -SPEED_OF_LIGHT_MILLI ||
            arg1_milli >= SPEED_OF_LIGHT_MILLI) return INVALID_RESULT;
        return lorentz_gamma((double)arg1_milli / 1000.0);
    }
    if (operation == 1 || operation == 2) {
        if (arg1_milli < 0 || arg1_milli > MAX_LENGTH_TIME_MILLI ||
            arg2_milli <= -SPEED_OF_LIGHT_MILLI || arg2_milli >= SPEED_OF_LIGHT_MILLI) return INVALID_RESULT;
        double quantity = (double)arg1_milli / 1000.0;
        double velocity = (double)arg2_milli / 1000.0;
        double gamma = lorentz_gamma(velocity);
        return operation == 1 ? quantity / gamma : quantity * gamma;
    }
    if (operation == 3) {
        if (arg1_milli < -SPEED_OF_LIGHT_MILLI || arg1_milli > SPEED_OF_LIGHT_MILLI ||
            arg2_milli <= -SPEED_OF_LIGHT_MILLI || arg2_milli >= SPEED_OF_LIGHT_MILLI) return INVALID_RESULT;
        double velocity_one = (double)arg1_milli / 1000.0;
        double frame_velocity = (double)arg2_milli / 1000.0;
        return (velocity_one - frame_velocity) /
               (1.0 - velocity_one * frame_velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT));
    }
    return INVALID_RESULT;
}
