module de_boor_bspline_curve_evaluation;

const MAX_INPUT_LENGTH: usz = 24;

fn bool finite(double value) {
    return value == value && value <= 1.0e308 && value >= -1.0e308;
}

fn bool exact_integer(double value, long low, long high, long* decoded) {
    if (!finite(value) || value < (double)low || value > (double)high || (double)(long)value != value) return false;
    *decoded = (long)value;
    return true;
}

fn bool valid(double* input, usz length, long* degree, long* count) {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return false;
    if (!exact_integer(input[0],1,3,degree) || !exact_integer(input[1],*degree+1,8,count) || !finite(input[2])) return false;
    usz knot_count = (usz)(*count + *degree + 1);
    if (length != 3 + knot_count + (usz)*count) return false;
    double* knots = input + 3;
    double* controls = input + 3 + knot_count;
    for (usz i=0; i<knot_count; i++) {
        if (!finite(knots[i]) || knots[i] < -1000.0 || knots[i] > 1000.0) return false;
        if (i > 0 && knots[i] < knots[i-1]) return false;
    }
    for (long i=0; i<*count; i++)
        if (!finite(controls[i]) || controls[i] < -1000.0 || controls[i] > 1000.0) return false;
    long run = 1;
    for (usz i=1; i<knot_count; i++) {
        if (knots[i] == knots[i-1]) run++; else run = 1;
        if (run > *degree+1) return false;
    }
    return knots[*degree] < knots[*count] && input[2] >= knots[*degree] && input[2] <= knots[*count];
}

fn double evaluate(double* input, long degree, long count) {
    usz knot_count = (usz)(count+degree+1);
    double* knots = input+3;
    double* controls = input+3+knot_count;
    double u = input[2];
    long span = degree;
    if (u == knots[count]) span = count-1;
    else while (span < count-1 && u >= knots[span+1]) span++;
    double[4] local = {};
    for (long j=0; j<=degree; j++) local[j] = controls[span-degree+j];
    for (long level=1; level<=degree; level++) {
        long slot = degree;
        while (slot >= level) {
            long left = span-degree+slot;
            long right = span+slot-level+1;
            double denominator = knots[right]-knots[left];
            double alpha = 0.0;
            if (denominator != 0.0) alpha = (u-knots[left])/denominator;
            local[slot] = (1.0-alpha)*local[slot-1]+alpha*local[slot];
            slot--;
        }
    }
    return local[degree];
}

fn long de_boor_bspline_curve_evaluation(double* input, usz input_length,
    double* output, usz output_capacity) @export("de_boor_bspline_curve_evaluation") {
    long degree; long count;
    if (!valid(input,input_length,&degree,&count)) return -1L;
    if (output == null || output_capacity < 1) return -2L;
    double result = evaluate(input,degree,count);
    if (!finite(result)) return -1L;
    output[0] = result;
    return 1L;
}
