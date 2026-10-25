module cbench_lame_mid_side;

const usz MAX_INPUT = 65;
const usz MAX_OUTPUT = 64;
const double SQRT2 = 1.414213562373095048801688724209698079;

fn long cbench_lame_mid_side(double* input, usz n, double* output, usz cap)
    @export("cbench_lame_mid_side")
{
    if (input == null || n == 0 || n > MAX_INPUT + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i] != input[i]) return -1;
    if (input[0] < 1.0 || input[0] > 32.0 || input[0] != (double)(long)input[0]) return -1;
    usz count = (usz)input[0];
    if (n != 1 + 2 * count) return -1;
    for (usz i = 1; i < n; i++) if (input[i] < -16.0 || input[i] > 16.0) return -1;
    double[MAX_OUTPUT] staged;
    double factor = SQRT2 * 0.5;
    for (usz i = 0; i < count; i++) {
        double left = input[1+i], right = input[1+count+i];
        staged[2*i] = (left + right) * factor;
        staged[2*i+1] = (left - right) * factor;
    }
    usz needed = 2 * count;
    if (output == null || cap < needed) return -2;
    for (usz i = 0; i < needed; i++) output[i] = staged[i];
    return (long)needed;
}
