module koch_snowflake;

const usz MAX_POINTS = 29;
const double MAX_COORDINATE = 1000.0;

fn long koch_snowflake(double* input, usz length, double* output, usz capacity)
    @export("koch_snowflake") {
    if (input == null || length < 2 || length > 20) return -1;
    double steps_value = input[0], count_value = input[1];
    if ((steps_value != 0.0 && steps_value != 1.0) ||
        (count_value != 2.0 && count_value != 3.0 && count_value != 4.0 && count_value != 5.0 &&
         count_value != 6.0 && count_value != 7.0 && count_value != 8.0)) return -1;
    usz steps = (usz)steps_value, point_count = (usz)count_value;
    if (length != 2 + 2 * point_count) return -1;
    for (usz i = 0; i < 2 * point_count; i++) {
        double value = input[i + 2];
        if (value != value || value < -MAX_COORDINATE || value > MAX_COORDINATE) return -1;
    }
    usz result_points = if steps == 0 then point_count else 4 * (point_count - 1) + 1;
    usz result_count = 2 * result_points;
    if (output == null || capacity < result_count) return -2;

    float[MAX_POINTS] ax, ay, bx, by;
    for (usz i = 0; i < point_count; i++) {
        ax[i] = (float)input[2 + 2 * i];
        ay[i] = (float)input[3 + 2 * i];
    }
    float* sx = &ax[0];
    float* sy = &ay[0];
    float* dxs = &bx[0];
    float* dys = &by[0];
    usz source_count = point_count;
    for (usz step = 0; step < steps; step++) {
        usz cursor = 0;
        for (usz i = 0; i + 1 < source_count; i++) {
            float x0 = sx[i], y0 = sy[i];
            float vx = sx[i + 1] - x0, vy = sy[i + 1] - y0;
            float tx = vx / 3.0f, ty = vy / 3.0f;
            float x1 = x0 + tx, y1 = y0 + ty;
            float rx = 0.49999997f * tx - 0.86602545f * ty;
            float ry = 0.86602545f * tx + 0.49999997f * ty;
            float x2 = x1 + rx, y2 = y1 + ry;
            float tx2 = (vx * 2.0f) / 3.0f, ty2 = (vy * 2.0f) / 3.0f;
            dxs[cursor] = x0; dys[cursor] = y0; cursor++;
            dxs[cursor] = x1; dys[cursor] = y1; cursor++;
            dxs[cursor] = x2; dys[cursor] = y2; cursor++;
            dxs[cursor] = x0 + tx2; dys[cursor] = y0 + ty2; cursor++;
        }
        dxs[cursor] = sx[source_count - 1]; dys[cursor] = sy[source_count - 1]; cursor++;
        source_count = cursor;
        float* temp = sx; sx = dxs; dxs = temp;
        temp = sy; sy = dys; dys = temp;
    }
    for (usz i = 0; i < result_points; i++) {
        output[2 * i] = (double)sx[i];
        output[2 * i + 1] = (double)sy[i];
    }
    (long)result_count
}
