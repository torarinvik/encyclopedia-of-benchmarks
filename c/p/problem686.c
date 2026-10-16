/* Find the nth power of two whose decimal prefix is 123. */
#include <stdint.h>

#define MAX_POSITION INT64_C(678910)
static const double LOG10_2 = 0.30102999566398114;
static const double LOWER_LIMIT = 0.08990511143939792;
static const double UPPER_LIMIT = 0.09342168516223506;
static const double ROUND_SCALE = 1000000000000000.0;

static double rounded_decimal_part(int64_t exponent)
{
    const double logarithm = LOG10_2 * (double)exponent;
    const int64_t integer_part = (int64_t)logarithm;
    const double difference = logarithm - (double)integer_part;
    const double scaled = difference * ROUND_SCALE;
    int64_t rounded = (int64_t)scaled;
    const double remainder = scaled - (double)rounded;
    if (remainder > 0.5 || (remainder == 0.5 && rounded % 2 != 0)) ++rounded;
    return (double)rounded / ROUND_SCALE;
}

int64_t problem686(int64_t number)
{
    if (number < 1 || number > MAX_POSITION) return -1;
    int64_t power_iterator = 90, position = 0, previous_power = 0;
    while (position < number) {
        const double difference = rounded_decimal_part(power_iterator);
        if (difference >= UPPER_LIMIT) power_iterator += 93;
        else if (difference < LOWER_LIMIT) power_iterator += 196;
        else { previous_power = power_iterator; power_iterator += 196; ++position; }
    }
    return previous_power;
}
