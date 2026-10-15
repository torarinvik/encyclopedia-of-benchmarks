/* Return the length of a circular arc; unit is 0 for degrees and 1 for radians. */
namespace { constexpr double pi = 3.141592653589793238462643383279502884; }

extern "C" double arc_length(double radius, double angle, double unit) noexcept
{
    return unit == 0.0 ? 2.0 * pi * radius * (angle / 360.0) : radius * angle;
}
