/* John Walker's Floating Point Benchmark, derived from the Marinchip
   Interactive Lens Design System (December 1980). Pinned origin:
   lac-dcc/Benchmarks Misc/fbench/fbench.c at 5d7b75df749241efa7a6e6f5be613d3fcc5cce38.
   Its header permits use, distribution, and modification when origin information is preserved. */
module freebench_fbench;

extern fn double sin(double x);
extern fn double cos(double x);
extern fn double tan(double x);
extern fn double asin(double x);

const long MAX_PASSES = 16;
const double INVALID_RESULT = -1.0e300;

struct RayState { double object_distance; double axis_slope_angle; }
const double[9] SPECTRAL_LINE = {0.0, 7621.0, 6869.955, 6562.816, 5895.944, 5269.557, 4861.344, 4340.477, 3968.494};
const double[4][4] LENS = {
    {27.05, 1.5137, 63.6, 0.52},
    {-16.68, 1.0, 0.0, 0.138},
    {-16.68, 1.6164, 36.7, 0.38},
    {-78.1, 1.0, 0.0, 0.0}
};

fn RayState trace_line(int line, double ray_height, bool paraxial) {
    double object_distance = 0.0;
    double axis_slope_angle = 0.0;
    double from_index = 1.0;
    for (int surface = 0; surface < 4; surface++) {
        double radius = LENS[surface][0];
        double nominal_index = LENS[surface][1];
        double abbe_number = LENS[surface][2];
        double thickness = LENS[surface][3];
        double to_index = nominal_index;
        if (to_index > 1.0) {
            to_index += ((SPECTRAL_LINE[4] - SPECTRAL_LINE[line])
                / (SPECTRAL_LINE[3] - SPECTRAL_LINE[6]))
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
                double refraction_sine = (from_index / to_index) * incidence_sine;
                double old_axis_slope_angle = axis_slope_angle;
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
            double incidence_angle = asin(incidence_sine);
            double refraction_sine = (from_index / to_index) * incidence_sine;
            double old_axis_slope_angle = axis_slope_angle;
            axis_slope_angle = axis_slope_angle + incidence_angle - asin(refraction_sine);
            double sagitta = sin((old_axis_slope_angle + incidence_angle) / 2.0);
            sagitta = 2.0 * radius * sagitta * sagitta;
            object_distance = (radius * sin(old_axis_slope_angle + incidence_angle))
                * (1.0 / tan(axis_slope_angle)) + sagitta;
        } else {
            double refraction_angle = -asin((from_index / to_index) * sin(axis_slope_angle));
            object_distance = object_distance * ((to_index * cos(-refraction_angle))
                / (from_index * cos(axis_slope_angle)));
            axis_slope_angle = -refraction_angle;
        }
        from_index = to_index;
        if (surface < 3) object_distance = object_distance - thickness;
    }
    return RayState{object_distance, axis_slope_angle};
}

fn double one_pass_projection(double ray_height) {
    RayState marginal_d = trace_line(4, ray_height, false);
    RayState paraxial_d = trace_line(4, ray_height, true);
    double marginal_c = trace_line(3, ray_height, false).object_distance;
    double marginal_f = trace_line(6, ray_height, false).object_distance;
    double spherical_aberration = paraxial_d.object_distance - marginal_d.object_distance;
    double sine_condition_aberration = 1.0 - (paraxial_d.object_distance * paraxial_d.axis_slope_angle)
        / (sin(marginal_d.axis_slope_angle) * marginal_d.object_distance);
    double chromatic_aberration = marginal_f - marginal_c;
    return spherical_aberration + sine_condition_aberration + chromatic_aberration;
}

fn double freebench_fbench(long* values, usz length) @export("freebench_fbench") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > MAX_PASSES) return INVALID_RESULT;
    double total = 0.0;
    for (long pass = 0; pass < values[0]; pass++) {
        double ray_height = 2.0 + 0.0002 * (double)pass;
        total += one_pass_projection(ray_height);
    }
    return total;
}
