module arithmetic_geometric_mean;

extern fn double sqrt(double value);

const double MAX_VALUE = 1000000.0;
const double INVALID_RESULT = -1.0;

fn double arithmetic_geometric_mean(double first, double second) @export("arithmetic_geometric_mean")
{
    if (first != first || second != second || first < 0.0 || second < 0.0 ||
        first > MAX_VALUE || second > MAX_VALUE) return INVALID_RESULT;
    if (first == second) return first;

    double arithmetic = first;
    double geometric = second;
    double previous;
    do {
        previous = arithmetic;
        double next_arithmetic = (arithmetic + geometric) / 2.0;
        double next_geometric = sqrt(arithmetic * geometric);
        arithmetic = next_arithmetic;
        geometric = next_geometric;
    } while (arithmetic != previous);
    return arithmetic;
}
