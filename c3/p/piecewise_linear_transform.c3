module piecewise_linear_transform;

fn long piecewise_linear_transform(long* input, usz length, char* output, usz capacity)
    @export("piecewise_linear_transform") {
    if (input == null || length < 1 || length > 256) return -1;
    for (usz index = 0; index < length; index++)
        if (input[index] < 0 || input[index] > 255) return -1;
    if (output == null || capacity < length) return -2;
    for (usz index = 0; index < length; index++) {
        double pixel = (double)input[index];
        double mapped;
        if (pixel <= 100.0) mapped = (50.0 / 100.0) * pixel;
        else if (pixel <= 180.0)
            mapped = ((200.0 - 50.0) / (180.0 - 100.0)) * (pixel - 100.0) + 50.0;
        else mapped = ((255.0 - 200.0) / (255.0 - 180.0)) * (pixel - 180.0) + 200.0;
        output[index] = (char)(uint8)mapped;
    }
    return (long)length;
}
