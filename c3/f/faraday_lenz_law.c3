module faraday_lenz_law;

fn long faraday_lenz_law(long* values, usz length) @export("faraday_lenz_law")
{
    if (values == null || length != 3 || values[0] < -1000000000 || values[0] > 1000000000 ||
        values[1] < -1000000000 || values[1] > 1000000000 || values[2] < 1 || values[2] > 1000000000) {
        return -9223372036854775807 - 1;
    }
    long numerator = -(values[0] - values[1]) * 10;
    long magnitude = numerator < 0 ? -numerator : numerator;
    long quotient = magnitude / values[2];
    long remainder = magnitude % values[2];
    if (2 * remainder > values[2] || (2 * remainder == values[2] && quotient % 2 != 0)) quotient++;
    return numerator < 0 ? -quotient : quotient;
}
