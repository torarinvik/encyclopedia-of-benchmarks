#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define SPEED_OF_LIGHT 299792458.0
#define SPEED_OF_LIGHT_MILLI INT64_C(299792458000)
#define MAX_LENGTH_TIME_MILLI INT64_C(1000000)
#define MAX_INPUT_LENGTH ((size_t)4)
#define INVALID_RESULT (-1.0e300)

static double lorentz_gamma(double velocity) {
    return 1.0 / sqrt(1.0 - velocity * velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT));
}

double relativity(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t operation = input[0];
    const int64_t arg1_milli = input[1];
    const int64_t arg2_milli = input[2];
    if (length != 3) return INVALID_RESULT;

    if (operation == 0) {
        if (arg2_milli != 0 || arg1_milli <= -SPEED_OF_LIGHT_MILLI ||
            arg1_milli >= SPEED_OF_LIGHT_MILLI) return INVALID_RESULT;
        return lorentz_gamma((double)arg1_milli / 1000.0);
    }
    if (operation == 1 || operation == 2) {
        if (arg1_milli < 0 || arg1_milli > MAX_LENGTH_TIME_MILLI ||
            arg2_milli <= -SPEED_OF_LIGHT_MILLI || arg2_milli >= SPEED_OF_LIGHT_MILLI)
            return INVALID_RESULT;
        const double quantity = (double)arg1_milli / 1000.0;
        const double velocity = (double)arg2_milli / 1000.0;
        const double gamma = lorentz_gamma(velocity);
        return operation == 1 ? quantity / gamma : quantity * gamma;
    }
    if (operation == 3) {
        if (arg1_milli < -SPEED_OF_LIGHT_MILLI || arg1_milli > SPEED_OF_LIGHT_MILLI ||
            arg2_milli <= -SPEED_OF_LIGHT_MILLI || arg2_milli >= SPEED_OF_LIGHT_MILLI)
            return INVALID_RESULT;
        const double velocity_one = (double)arg1_milli / 1000.0;
        const double frame_velocity = (double)arg2_milli / 1000.0;
        return (velocity_one - frame_velocity) /
               (1.0 - velocity_one * frame_velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT));
    }
    return INVALID_RESULT;
}
