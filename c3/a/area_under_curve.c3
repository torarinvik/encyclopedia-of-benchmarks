module area_under_curve;

const MAX_STEPS = 10000;
const MAX_COORD_MILLI = 100000;
const OUTPUT_SCALE = 1000000.0;

fn double sample_value(long function_id, double x) {
    if (function_id == 0) return 5.0;
    if (function_id == 1) return x;
    return x * x;
}

// Integrate one of the documented sample functions with composite trapezoids.
fn long area_under_curve(long* input, usz length) @export("area_under_curve") {
    if (input == null || length != 4) return -1;
    long function_id = input[0];
    long start_milli = input[1];
    long end_milli = input[2];
    long steps = input[3];
    if (function_id < 0 || function_id > 2 || start_milli < 0 || start_milli > MAX_COORD_MILLI ||
        end_milli < 0 || end_milli > MAX_COORD_MILLI || steps < 1 || steps > MAX_STEPS) return -1;
    long low_milli = start_milli < end_milli ? start_milli : end_milli;
    long high_milli = start_milli < end_milli ? end_milli : start_milli;
    double start = (double)low_milli / 1000.0;
    double end = (double)high_milli / 1000.0;
    double width = (end - start) / (double)steps;
    double x1 = start;
    double y1 = sample_value(function_id, x1);
    double area = 0.0;
    for (long index = 0; index < steps; index++) {
        double x2 = x1 + width;
        double y2 = sample_value(function_id, x2);
        area += (y1 + y2) * width * 0.5;
        x1 = x2;
        y1 = y2;
    }
    return (long)(area * OUTPUT_SCALE + 0.5);
}
