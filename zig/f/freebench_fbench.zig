// John Walker's Floating Point Benchmark, derived from the Marinchip
// Interactive Lens Design System (December 1980). Pinned origin:
// lac-dcc/Benchmarks/Misc/fbench/fbench.c at 5d7b75df749241efa7a6e6f5be613d3fcc5cce38.
// The source permits use, distribution, and modification when origin information is preserved.
const MAX_PASSES: i64 = 16;
const INVALID_RESULT: f64 = -1.0e300;
const SPECTRAL_LINE = [_]f64{ 0.0, 7621.0, 6869.955, 6562.816, 5895.944, 5269.557, 4861.344, 4340.477, 3968.494 };
const LENS = [_][4]f64{
    .{ 27.05, 1.5137, 63.6, 0.52 },
    .{ -16.68, 1.0, 0.0, 0.138 },
    .{ -16.68, 1.6164, 36.7, 0.38 },
    .{ -78.1, 1.0, 0.0, 0.0 },
};

const RayState = struct {
    object_distance: f64,
    axis_slope_angle: f64,
};

fn traceLine(line: usize, initial_height: f64, paraxial: bool) RayState {
    var object_distance: f64 = 0.0;
    var ray_height = initial_height;
    var axis_slope_angle: f64 = 0.0;
    var from_index: f64 = 1.0;
    for (0..4) |surface| {
        const radius = LENS[surface][0];
        const nominal_index = LENS[surface][1];
        const abbe_number = LENS[surface][2];
        const thickness = LENS[surface][3];
        var to_index = nominal_index;
        if (to_index > 1.0) {
            to_index += ((SPECTRAL_LINE[4] - SPECTRAL_LINE[line])
                / (SPECTRAL_LINE[3] - SPECTRAL_LINE[6]))
                * ((nominal_index - 1.0) / abbe_number);
        }

        if (paraxial) {
            if (radius != 0.0) {
                var incidence_sine: f64 = undefined;
                if (object_distance == 0.0) {
                    axis_slope_angle = 0.0;
                    incidence_sine = ray_height / radius;
                } else {
                    incidence_sine = ((object_distance - radius) / radius) * axis_slope_angle;
                }
                const refraction_sine = (from_index / to_index) * incidence_sine;
                const old_axis_slope_angle = axis_slope_angle;
                axis_slope_angle = axis_slope_angle + incidence_sine - refraction_sine;
                if (object_distance != 0.0) ray_height = object_distance * old_axis_slope_angle;
                object_distance = ray_height / axis_slope_angle;
            } else {
                object_distance = object_distance * (to_index / from_index);
                axis_slope_angle = axis_slope_angle * (from_index / to_index);
            }
        } else if (radius != 0.0) {
            var incidence_sine: f64 = undefined;
            if (object_distance == 0.0) {
                axis_slope_angle = 0.0;
                incidence_sine = ray_height / radius;
            } else {
                incidence_sine = ((object_distance - radius) / radius) * @sin(axis_slope_angle);
            }
            const incidence_angle = @asin(incidence_sine);
            const refraction_sine = (from_index / to_index) * incidence_sine;
            const old_axis_slope_angle = axis_slope_angle;
            axis_slope_angle = axis_slope_angle + incidence_angle - @asin(refraction_sine);
            var sagitta = @sin((old_axis_slope_angle + incidence_angle) / 2.0);
            sagitta = 2.0 * radius * sagitta * sagitta;
            object_distance = (radius * @sin(old_axis_slope_angle + incidence_angle))
                * (1.0 / @tan(axis_slope_angle)) + sagitta;
        } else {
            const refraction_angle = -@asin((from_index / to_index) * @sin(axis_slope_angle));
            object_distance = object_distance * ((to_index * @cos(-refraction_angle))
                / (from_index * @cos(axis_slope_angle)));
            axis_slope_angle = -refraction_angle;
        }

        from_index = to_index;
        if (surface < 3) object_distance = object_distance - thickness;
    }
    return .{ .object_distance = object_distance, .axis_slope_angle = axis_slope_angle };
}

fn onePassProjection(ray_height: f64) f64 {
    const marginal_d = traceLine(4, ray_height, false);
    const paraxial_d = traceLine(4, ray_height, true);
    const marginal_c = traceLine(3, ray_height, false).object_distance;
    const marginal_f = traceLine(6, ray_height, false).object_distance;
    const spherical_aberration = paraxial_d.object_distance - marginal_d.object_distance;
    const sine_condition_aberration = 1.0 - (paraxial_d.object_distance * paraxial_d.axis_slope_angle)
        / (@sin(marginal_d.axis_slope_angle) * marginal_d.object_distance);
    const chromatic_aberration = marginal_f - marginal_c;
    return spherical_aberration + sine_condition_aberration + chromatic_aberration;
}

export fn freebench_fbench(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 1) return INVALID_RESULT;
    const passes = values[0];
    if (passes < 1 or passes > MAX_PASSES) return INVALID_RESULT;
    var total: f64 = 0.0;
    var pass: i64 = 0;
    while (pass < passes) : (pass += 1) {
        const ray_height = 2.0 + 0.0002 * @as(f64, @floatFromInt(pass));
        total += onePassProjection(ray_height);
    }
    return total;
}
