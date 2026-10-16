#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_DENSITY_PPM INT64_C(1000000)

double hubble_parameter(const int64_t *values, size_t length)
{
    if (values == NULL || length != 5) return INVALID_RESULT;
    const int64_t h0_x10 = values[0], radiation_ppm = values[1], matter_ppm = values[2], dark_energy_ppm = values[3], redshift_milli = values[4];
    if (h0_x10 < -2000 || h0_x10 > 2000 || radiation_ppm < 0 || radiation_ppm > MAX_DENSITY_PPM ||
        matter_ppm < 0 || matter_ppm > MAX_DENSITY_PPM || dark_energy_ppm < 0 || dark_energy_ppm > MAX_DENSITY_PPM ||
        radiation_ppm + matter_ppm + dark_energy_ppm > MAX_DENSITY_PPM || redshift_milli < 0 || redshift_milli > 10000) return INVALID_RESULT;
    const double hubble_constant = (double)h0_x10 / 10.0;
    const double radiation_density = (double)radiation_ppm / 1000000.0;
    const double matter_density = (double)matter_ppm / 1000000.0;
    const double dark_energy = (double)dark_energy_ppm / 1000000.0;
    const double redshift = (double)redshift_milli / 1000.0;
    const double curvature = 1.0 - (matter_density + radiation_density + dark_energy);
    const double z1 = redshift + 1.0;
    const double e2 = radiation_density * pow(z1, 4.0) + matter_density * pow(z1, 3.0) + curvature * pow(z1, 2.0) + dark_energy;
    return hubble_constant * pow(e2, 1.0 / 2.0);
}
