// John Walker's Floating Point Benchmark, derived from the Marinchip
// Interactive Lens Design System (December 1980). Pinned origin:
// lac-dcc/Benchmarks/Misc/fbench/fbench.c at 5d7b75df749241efa7a6e6f5be613d3fcc5cce38.
// The source permits use, distribution, and modification when origin information is preserved.
const MAX_PASSES: i64 = 16;
const INVALID_RESULT: f64 = -1.0e300;
const SPECTRAL_LINE: [f64; 9] = [0.0, 7621.0, 6869.955, 6562.816, 5895.944, 5269.557, 4861.344, 4340.477, 3968.494];
const LENS: [[f64; 4]; 4] = [
    [27.05, 1.5137, 63.6, 0.52],
    [-16.68, 1.0, 0.0, 0.138],
    [-16.68, 1.6164, 36.7, 0.38],
    [-78.1, 1.0, 0.0, 0.0],
];

struct RayState {
    object_distance: f64,
    axis_slope_angle: f64,
}

fn trace_line(line: usize, initial_height: f64, paraxial: bool) -> RayState {
    let mut object_distance = 0.0;
    let mut ray_height = initial_height;
    let mut axis_slope_angle = 0.0;
    let mut from_index = 1.0;
    for surface in 0..4 {
        let radius = LENS[surface][0];
        let nominal_index = LENS[surface][1];
        let abbe_number = LENS[surface][2];
        let thickness = LENS[surface][3];
        let mut to_index = nominal_index;
        if to_index > 1.0 {
            to_index += ((SPECTRAL_LINE[4] - SPECTRAL_LINE[line])
                / (SPECTRAL_LINE[3] - SPECTRAL_LINE[6]))
                * ((nominal_index - 1.0) / abbe_number);
        }

        if paraxial {
            if radius != 0.0 {
                let incidence_sine = if object_distance == 0.0 {
                    axis_slope_angle = 0.0;
                    ray_height / radius
                } else {
                    ((object_distance - radius) / radius) * axis_slope_angle
                };
                let refraction_sine = (from_index / to_index) * incidence_sine;
                let old_axis_slope_angle = axis_slope_angle;
                axis_slope_angle = axis_slope_angle + incidence_sine - refraction_sine;
                if object_distance != 0.0 { ray_height = object_distance * old_axis_slope_angle; }
                object_distance = ray_height / axis_slope_angle;
            } else {
                object_distance = object_distance * (to_index / from_index);
                axis_slope_angle = axis_slope_angle * (from_index / to_index);
            }
        } else if radius != 0.0 {
            let incidence_sine = if object_distance == 0.0 {
                axis_slope_angle = 0.0;
                ray_height / radius
            } else {
                ((object_distance - radius) / radius) * axis_slope_angle.sin()
            };
            let incidence_angle = incidence_sine.asin();
            let refraction_sine = (from_index / to_index) * incidence_sine;
            let old_axis_slope_angle = axis_slope_angle;
            axis_slope_angle = axis_slope_angle + incidence_angle - refraction_sine.asin();
            let mut sagitta = ((old_axis_slope_angle + incidence_angle) / 2.0).sin();
            sagitta = 2.0 * radius * sagitta * sagitta;
            object_distance = (radius * (old_axis_slope_angle + incidence_angle).sin())
                * (1.0 / axis_slope_angle.tan()) + sagitta;
        } else {
            let refraction_angle = -((from_index / to_index) * axis_slope_angle.sin()).asin();
            object_distance = object_distance * ((to_index * (-refraction_angle).cos())
                / (from_index * axis_slope_angle.cos()));
            axis_slope_angle = -refraction_angle;
        }

        from_index = to_index;
        if surface < 3 { object_distance = object_distance - thickness; }
    }
    RayState { object_distance, axis_slope_angle }
}

fn one_pass_projection(ray_height: f64) -> f64 {
    let marginal_d = trace_line(4, ray_height, false);
    let paraxial_d = trace_line(4, ray_height, true);
    let marginal_c = trace_line(3, ray_height, false).object_distance;
    let marginal_f = trace_line(6, ray_height, false).object_distance;
    let spherical_aberration = paraxial_d.object_distance - marginal_d.object_distance;
    let sine_condition_aberration = 1.0 - (paraxial_d.object_distance * paraxial_d.axis_slope_angle)
        / (marginal_d.axis_slope_angle.sin() * marginal_d.object_distance);
    let chromatic_aberration = marginal_f - marginal_c;
    spherical_aberration + sine_condition_aberration + chromatic_aberration
}

#[no_mangle]
pub unsafe extern "C" fn freebench_fbench(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return INVALID_RESULT; }
    let passes = *values;
    if !(1..=MAX_PASSES).contains(&passes) { return INVALID_RESULT; }
    let mut total = 0.0;
    for pass in 0..passes {
        let ray_height = 2.0 + 0.0002 * pass as f64;
        total += one_pass_projection(ray_height);
    }
    total
}
