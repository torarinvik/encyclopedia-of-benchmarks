const max_image_side: usize = 8;
const max_kernel_side: usize = 4;
const max_filters: usize = 3;
const max_hidden: usize = 8;
const max_outputs: usize = 4;
const max_entry_micro: i64 = 1_000_000;

fn sigmoid(value: f64) f64 { return 1.0 / (1.0 + @exp(-value)); }

fn round_three(value: f64) f64 {
    const scaled = value * 1000.0;
    const lower = @floor(scaled);
    var integer: i64 = @intFromFloat(lower);
    const fraction = scaled - lower;
    if (fraction > 0.5 or (fraction == 0.5 and @rem(integer, 2) != 0)) integer += 1;
    return @as(f64, @floatFromInt(integer)) / 1000.0;
}

fn write_f64_le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn convolution_neural_network(values: [*c]const i64, length: usize,
                                     output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 7 or length > 2048) return -1;
    const image_side_value = values[0];
    const kernel_side_value = values[1];
    const stride_value = values[2];
    const filters_value = values[3];
    const pool_value = values[4];
    const hidden_value = values[5];
    const outputs_value = values[6];
    if (image_side_value < 2 or image_side_value > max_image_side or
        kernel_side_value < 1 or kernel_side_value > max_kernel_side or
        stride_value < 1 or stride_value > 4 or filters_value < 1 or filters_value > max_filters or
        pool_value < 1 or pool_value > 2 or hidden_value < 1 or hidden_value > max_hidden or
        outputs_value < 1 or outputs_value > max_outputs or kernel_side_value > image_side_value) return -1;
    const image_side: usize = @intCast(image_side_value);
    const kernel_side: usize = @intCast(kernel_side_value);
    const stride: usize = @intCast(stride_value);
    const filters: usize = @intCast(filters_value);
    const pool_side: usize = @intCast(pool_value);
    const hidden: usize = @intCast(hidden_value);
    const outputs: usize = @intCast(outputs_value);
    const conv_side = (image_side - kernel_side) / stride + 1;
    if (conv_side < pool_side or conv_side % pool_side != 0) return -1;
    const pooled_side = conv_side / pool_side;
    const feature_count = filters * pooled_side * pooled_side;
    const image_count = image_side * image_side;
    const kernel_count = filters * kernel_side * kernel_side;
    const hidden_weight_count = hidden * feature_count;
    const output_weight_count = outputs * hidden;
    const expected_length = 7 + image_count + kernel_count + filters + hidden_weight_count + output_weight_count + hidden + outputs;
    if (length != expected_length or feature_count > 192) return -1;

    var image: [64]f64 = @splat(0.0);
    var kernels: [48]f64 = @splat(0.0);
    var conv_bias: [3]f64 = @splat(0.0);
    var hidden_weights: [1536]f64 = @splat(0.0);
    var output_weights: [32]f64 = @splat(0.0);
    var hidden_bias: [8]f64 = @splat(0.0);
    var output_bias: [4]f64 = @splat(0.0);
    var feature_maps: [192]f64 = @splat(0.0);
    var flattened: [192]f64 = @splat(0.0);
    var hidden_output: [8]f64 = @splat(0.0);
    var position: usize = 7;
    for (0..image_count) |index| {
        const raw = values[position]; position += 1;
        if (raw < 0 or raw > max_entry_micro) return -1;
        image[index] = @as(f64, @floatFromInt(raw)) / 1_000_000.0;
    }
    for (0..kernel_count) |index| {
        const raw = values[position]; position += 1;
        if (raw < -500_000 or raw > 500_000) return -1;
        kernels[index] = @as(f64, @floatFromInt(raw)) / 1_000_000.0;
    }
    for (0..filters) |index| {
        const raw = values[position]; position += 1;
        if (raw < -max_entry_micro or raw > max_entry_micro) return -1;
        conv_bias[index] = @as(f64, @floatFromInt(raw)) / 1_000_000.0;
    }
    for (0..hidden_weight_count) |index| {
        const raw = values[position]; position += 1;
        if (raw < -500_000 or raw > 500_000) return -1;
        hidden_weights[index] = @as(f64, @floatFromInt(raw)) / 1_000_000.0;
    }
    for (0..output_weight_count) |index| {
        const raw = values[position]; position += 1;
        if (raw < -500_000 or raw > 500_000) return -1;
        output_weights[index] = @as(f64, @floatFromInt(raw)) / 1_000_000.0;
    }
    for (0..hidden) |index| {
        const raw = values[position]; position += 1;
        if (raw < -max_entry_micro or raw > max_entry_micro) return -1;
        hidden_bias[index] = @as(f64, @floatFromInt(raw)) / 1_000_000.0;
    }
    for (0..outputs) |index| {
        const raw = values[position]; position += 1;
        if (raw < -max_entry_micro or raw > max_entry_micro) return -1;
        output_bias[index] = @as(f64, @floatFromInt(raw)) / 1_000_000.0;
    }
    const output_bytes = outputs * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..filters) |filter| {
        for (0..conv_side) |top| {
            for (0..conv_side) |left| {
                var total: f64 = 0.0;
                for (0..kernel_side) |row| {
                    for (0..kernel_side) |column| {
                        total += image[(top * stride + row) * image_side + left * stride + column] *
                            kernels[filter * kernel_side * kernel_side + row * kernel_side + column];
                    }
                }
                feature_maps[(filter * conv_side + top) * conv_side + left] = sigmoid(total - conv_bias[filter]);
            }
        }
    }
    var feature_index: usize = 0;
    const pool_area = pool_side * pool_side;
    for (0..filters) |filter| {
        var top: usize = 0;
        while (top < conv_side) : (top += pool_side) {
            var left: usize = 0;
            while (left < conv_side) : (left += pool_side) {
                var total: f64 = 0.0;
                for (0..pool_side) |row| {
                    for (0..pool_side) |column| {
                        total += feature_maps[(filter * conv_side + top + row) * conv_side + left + column];
                    }
                }
                flattened[feature_index] = total / @as(f64, @floatFromInt(pool_area));
                feature_index += 1;
            }
        }
    }
    for (0..hidden) |unit| {
        var total: f64 = 0.0;
        for (0..feature_count) |index| total += flattened[index] * hidden_weights[unit * feature_count + index];
        hidden_output[unit] = sigmoid(total - hidden_bias[unit]);
    }
    for (0..outputs) |unit| {
        var total: f64 = 0.0;
        for (0..hidden) |index| total += hidden_output[index] * output_weights[unit * hidden + index];
        write_f64_le(output, unit * 8, round_three(sigmoid(total - output_bias[unit])));
    }
    return @intCast(output_bytes);
}
