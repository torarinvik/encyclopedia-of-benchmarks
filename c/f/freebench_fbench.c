/*
 * Independent bounded implementation of John Walker's Floating Point
 * Benchmark, derived from the Marinchip Interactive Lens Design System
 * (December 1980). Pinned source: lac-dcc/Benchmarks, Misc/fbench/fbench.c,
 * commit 5d7b75df749241efa7a6e6f5be613d3fcc5cce38. The original header
 * permits use, distribution, and modification when origin information is
 * preserved.
 */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PASSES 16
#define INVALID_RESULT (-1.0e300)

typedef struct {
    double object_distance;
    double axis_slope_angle;
} RayState;

static const double spectral_line[9] = {
    0.0, 7621.0, 6869.955, 6562.816, 5895.944,
    5269.557, 4861.344, 4340.477, 3968.494
};

static const double lens[4][4] = {
    {27.05, 1.5137, 63.6, 0.52},
    {-16.68, 1.0, 0.0, 0.138},
    {-16.68, 1.6164, 36.7, 0.38},
    {-78.1, 1.0, 0.0, 0.0}
};

static RayState trace_line(int line, double ray_height, int paraxial) {
    double object_distance = 0.0;
    double axis_slope_angle = 0.0;
    double from_index = 1.0;
    for (int surface = 0; surface < 4; ++surface) {
        const double radius = lens[surface][0];
        const double nominal_index = lens[surface][1];
        const double abbe_number = lens[surface][2];
        const double thickness = lens[surface][3];
        double to_index = nominal_index;
        if (to_index > 1.0) {
            to_index += ((spectral_line[4] - spectral_line[line])
                / (spectral_line[3] - spectral_line[6]))
                * ((nominal_index - 1.0) / abbe_number);
        }

        if (paraxial) {
            if (radius != 0.0) {
                double incidence_sine;
                if (object_distance == 0.0) {
                    axis_slope_angle = 0.0;
                    incidence_sine = ray_height / radius;
                } else {
                    incidence_sine = ((object_distance - radius) / radius) * axis_slope_angle;
                }
                const double refraction_sine = (from_index / to_index) * incidence_sine;
                const double old_axis_slope_angle = axis_slope_angle;
                axis_slope_angle = axis_slope_angle + incidence_sine - refraction_sine;
                if (object_distance != 0.0) ray_height = object_distance * old_axis_slope_angle;
                object_distance = ray_height / axis_slope_angle;
            } else {
                object_distance = object_distance * (to_index / from_index);
                axis_slope_angle = axis_slope_angle * (from_index / to_index);
            }
        } else if (radius != 0.0) {
            double incidence_sine;
            if (object_distance == 0.0) {
                axis_slope_angle = 0.0;
                incidence_sine = ray_height / radius;
            } else {
                incidence_sine = ((object_distance - radius) / radius) * sin(axis_slope_angle);
            }
            const double incidence_angle = asin(incidence_sine);
            const double refraction_sine = (from_index / to_index) * incidence_sine;
            const double old_axis_slope_angle = axis_slope_angle;
            axis_slope_angle = axis_slope_angle + incidence_angle - asin(refraction_sine);
            double sagitta = sin((old_axis_slope_angle + incidence_angle) / 2.0);
            sagitta = 2.0 * radius * sagitta * sagitta;
            object_distance = (radius * sin(old_axis_slope_angle + incidence_angle))
                * (1.0 / tan(axis_slope_angle)) + sagitta;
        } else {
            const double refraction_angle = -asin((from_index / to_index) * sin(axis_slope_angle));
            object_distance = object_distance * ((to_index * cos(-refraction_angle))
                / (from_index * cos(axis_slope_angle)));
            axis_slope_angle = -refraction_angle;
        }

        from_index = to_index;
        if (surface < 3) object_distance = object_distance - thickness;
    }
    return (RayState){object_distance, axis_slope_angle};
}

static double one_pass_projection(double ray_height) {
    const RayState marginal_d = trace_line(4, ray_height, 0);
    const RayState paraxial_d = trace_line(4, ray_height, 1);
    const double marginal_c = trace_line(3, ray_height, 0).object_distance;
    const double marginal_f = trace_line(6, ray_height, 0).object_distance;
    const double spherical_aberration = paraxial_d.object_distance - marginal_d.object_distance;
    const double sine_condition_aberration = 1.0 - (paraxial_d.object_distance * paraxial_d.axis_slope_angle)
        / (sin(marginal_d.axis_slope_angle) * marginal_d.object_distance);
    const double chromatic_aberration = marginal_f - marginal_c;
    return spherical_aberration + sine_condition_aberration + chromatic_aberration;
}

double freebench_fbench(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_PASSES) return INVALID_RESULT;
    double total = 0.0;
    for (int64_t pass = 0; pass < values[0]; ++pass) {
        const double ray_height = 2.0 + 0.0002 * (double)pass;
        total += one_pass_projection(ray_height);
    }
    return isfinite(total) ? total : INVALID_RESULT;
}
