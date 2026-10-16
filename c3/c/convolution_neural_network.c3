module convolution_neural_network;

const usz MAX_IMAGE_SIDE = 8;
const usz MAX_KERNEL_SIDE = 4;
const usz MAX_FILTERS = 3;
const usz MAX_HIDDEN = 8;
const usz MAX_OUTPUTS = 4;
const usz MAX_FEATURES = 192;
const long MAX_ENTRY_MICRO = 1000000;
extern fn double exp(double value);
extern fn double floor(double value);

fn double sigmoid(double value) {
    return 1.0 / (1.0 + exp(-value));
}

fn double round_three(double value) {
    double scaled = value * 1000.0;
    double lower = floor(scaled);
    long integer = (long)lower;
    double fraction = scaled - lower;
    if (fraction > 0.5 || (fraction == 0.5 && integer % 2 != 0)) integer++;
    return (double)integer / 1000.0;
}

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = bitcast(value, ulong);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long convolution_neural_network(long* values, usz length, char* output, usz output_capacity)
    @export("convolution_neural_network") {
    if (values == null || length < 7 || length > 2048) return -1;
    long image_side_value = values[0];
    long kernel_side_value = values[1];
    long stride_value = values[2];
    long filters_value = values[3];
    long pool_value = values[4];
    long hidden_value = values[5];
    long outputs_value = values[6];
    if (image_side_value < 2 || image_side_value > (long)MAX_IMAGE_SIDE ||
        kernel_side_value < 1 || kernel_side_value > (long)MAX_KERNEL_SIDE ||
        stride_value < 1 || stride_value > 4 || filters_value < 1 || filters_value > (long)MAX_FILTERS ||
        pool_value < 1 || pool_value > 2 || hidden_value < 1 || hidden_value > (long)MAX_HIDDEN ||
        outputs_value < 1 || outputs_value > (long)MAX_OUTPUTS || kernel_side_value > image_side_value) return -1;
    usz image_side = (usz)image_side_value;
    usz kernel_side = (usz)kernel_side_value;
    usz stride = (usz)stride_value;
    usz filters = (usz)filters_value;
    usz pool_side = (usz)pool_value;
    usz hidden = (usz)hidden_value;
    usz outputs = (usz)outputs_value;
    usz conv_side = (image_side - kernel_side) / stride + 1;
    if (conv_side < pool_side || conv_side % pool_side != 0) return -1;
    usz pooled_side = conv_side / pool_side;
    usz feature_count = filters * pooled_side * pooled_side;
    usz image_count = image_side * image_side;
    usz kernel_count = filters * kernel_side * kernel_side;
    usz hidden_weight_count = hidden * feature_count;
    usz output_weight_count = outputs * hidden;
    usz expected_length = 7 + image_count + kernel_count + filters + hidden_weight_count + output_weight_count + hidden + outputs;
    if (length != expected_length || feature_count > MAX_FEATURES) return -1;

    double[64] image;
    double[48] kernels;
    double[3] conv_bias;
    double[1536] hidden_weights;
    double[32] output_weights;
    double[8] hidden_bias;
    double[4] output_bias;
    double[192] feature_maps;
    double[192] flattened;
    double[8] hidden_output;
    usz position = 7;
    for (usz index = 0; index < image_count; index++) {
        long raw = values[position++];
        if (raw < 0 || raw > MAX_ENTRY_MICRO) return -1;
        image[index] = (double)raw / 1000000.0;
    }
    for (usz index = 0; index < kernel_count; index++) {
        long raw = values[position++];
        if (raw < -500000 || raw > 500000) return -1;
        kernels[index] = (double)raw / 1000000.0;
    }
    for (usz index = 0; index < filters; index++) {
        long raw = values[position++];
        if (raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO) return -1;
        conv_bias[index] = (double)raw / 1000000.0;
    }
    for (usz index = 0; index < hidden_weight_count; index++) {
        long raw = values[position++];
        if (raw < -500000 || raw > 500000) return -1;
        hidden_weights[index] = (double)raw / 1000000.0;
    }
    for (usz index = 0; index < output_weight_count; index++) {
        long raw = values[position++];
        if (raw < -500000 || raw > 500000) return -1;
        output_weights[index] = (double)raw / 1000000.0;
    }
    for (usz index = 0; index < hidden; index++) {
        long raw = values[position++];
        if (raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO) return -1;
        hidden_bias[index] = (double)raw / 1000000.0;
    }
    for (usz index = 0; index < outputs; index++) {
        long raw = values[position++];
        if (raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO) return -1;
        output_bias[index] = (double)raw / 1000000.0;
    }
    usz output_bytes = outputs * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    for (usz filter = 0; filter < filters; filter++) {
        for (usz top = 0; top < conv_side; top++) {
            for (usz left = 0; left < conv_side; left++) {
                double total = 0.0;
                for (usz row = 0; row < kernel_side; row++) {
                    for (usz column = 0; column < kernel_side; column++) {
                        total += image[(top * stride + row) * image_side + left * stride + column] *
                            kernels[filter * kernel_side * kernel_side + row * kernel_side + column];
                    }
                }
                feature_maps[(filter * conv_side + top) * conv_side + left] = sigmoid(total - conv_bias[filter]);
            }
        }
    }
    usz feature_index = 0;
    usz pool_area = pool_side * pool_side;
    for (usz filter = 0; filter < filters; filter++) {
        for (usz top = 0; top < conv_side; top += pool_side) {
            for (usz left = 0; left < conv_side; left += pool_side) {
                double total = 0.0;
                for (usz row = 0; row < pool_side; row++) {
                    for (usz column = 0; column < pool_side; column++) {
                        total += feature_maps[(filter * conv_side + top + row) * conv_side + left + column];
                    }
                }
                flattened[feature_index++] = total / (double)pool_area;
            }
        }
    }
    for (usz unit = 0; unit < hidden; unit++) {
        double total = 0.0;
        for (usz index = 0; index < feature_count; index++) total += flattened[index] * hidden_weights[unit * feature_count + index];
        hidden_output[unit] = sigmoid(total - hidden_bias[unit]);
    }
    for (usz unit = 0; unit < outputs; unit++) {
        double total = 0.0;
        for (usz index = 0; index < hidden; index++) total += hidden_output[index] * output_weights[unit * hidden + index];
        write_f64_le(output, unit * 8, round_three(sigmoid(total - output_bias[unit])));
    }
    return (long)output_bytes;
}
