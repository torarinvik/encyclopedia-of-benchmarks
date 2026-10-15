// Apply an affine conversion in the source operation order: slope * x + intercept.
extern "C" double affine_converter(double slope, double x, double intercept) noexcept
{
    return slope * x + intercept;
}
