/* Return the length of a circular arc; unit is 0 for degrees and 1 for radians. */
#define PI 3.141592653589793238462643383279502884

double arc_length(double radius, double angle, double unit)
{
    return unit == 0.0 ? 2.0 * PI * radius * (angle / 360.0) : radius * angle;
}
