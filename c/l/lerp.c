/* Binary64 linear interpolation in the classic start + t * (end - start) form. */
double lerp(double start, double end, double t)
{
    return start + t * (end - start);
}
