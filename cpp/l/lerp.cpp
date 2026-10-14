/* Binary64 linear interpolation in the classic start + t * (end - start) form. */
extern "C" double lerp(double start, double end, double t) noexcept
{
    return start + t * (end - start);
}
