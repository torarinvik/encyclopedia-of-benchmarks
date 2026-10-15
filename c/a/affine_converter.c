/* Apply an affine conversion in the source operation order: slope * x + intercept. */
double affine_converter(double slope, double x, double intercept)
{
    return slope * x + intercept;
}
