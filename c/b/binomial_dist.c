#include <math.h>

/* Probability of exactly x successes in n Bernoulli trials. */
double binomial_dist(double n, double p, double x)
{
    double numerator = n;
    double denominator = x;
    for (int i = (int)n - 1; i >= ((int)n - (int)x + 1); --i) {
        numerator *= (double)i;
    }
    for (int i = 1; i < (int)x; ++i) {
        denominator *= (double)i;
    }
    return (numerator / denominator) * pow(p, x) * pow(1.0 - p, n - x);
}
