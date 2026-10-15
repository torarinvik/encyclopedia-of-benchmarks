module assembly_line_scheduling;

// Minimum time to cross two assembly lines using station-by-station dynamic programming.
fn long assembly_line_scheduling(long* values, usz length, char* output, usz output_capacity)
    @export("assembly_line_scheduling")
{
    if (values == null || length < 7 || values[0] < 1 || values[0] > 64) return -1;
    usz n = (usz)values[0];
    if (length != 4 * n + 3) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 1000) return -1;
    }

    usz a0 = 1;
    usz a1 = a0 + n;
    usz t0 = a1 + n;
    usz t1 = t0 + n - 1;
    usz entry = t1 + n - 1;
    long line0 = values[entry] + values[a0];
    long line1 = values[entry + 1] + values[a1];
    for (usz station = 1; station < n; station++) {
        long stay0 = line0 + values[a0 + station];
        long switch0 = line1 + values[t1 + station - 1] + values[a0 + station];
        long stay1 = line1 + values[a1 + station];
        long switch1 = line0 + values[t0 + station - 1] + values[a1 + station];
        line0 = stay0 < switch0 ? stay0 : switch0;
        line1 = stay1 < switch1 ? stay1 : switch1;
    }
    long total0 = line0 + values[entry + 2];
    long total1 = line1 + values[entry + 3];
    long answer = total0 < total1 ? total0 : total1;
    if (output == null || output_capacity < 4) return -2;
    for (usz byte = 0; byte < 4; byte++) {
        output[byte] = (char)((answer >> (8 * byte)) & 255);
    }
    return 4;
}
