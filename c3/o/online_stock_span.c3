module online_stock_span;

const MAX_DAYS = 4095;

fn long online_stock_span(long* input, usz length, char* output, usz output_capacity)
    @export("online_stock_span")
{
    if (input == null || length < 2 || input[0] < 1 || input[0] > MAX_DAYS) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;
    for (usz day = 0; day < count; day++) {
        if (input[day + 1] < 1 || input[day + 1] > 100000) return -1;
    }
    usz output_bytes = count * 8;
    if (output_capacity < output_bytes || output == null) return -2;

    usz[MAX_DAYS] decreasing;
    usz top = 0;
    for (usz day = 0; day < count; day++) {
        long price = input[day + 1];
        while (top > 0 && input[decreasing[top - 1] + 1] <= price) top--;
        usz span = top == 0 ? day + 1 : day - decreasing[top - 1];
        ulong encoded = (ulong)span;
        for (usz byte = 0; byte < 8; byte++) {
            output[day * 8 + byte] = (char)((encoded >> (byte * 8)) & 255);
        }
        decreasing[top] = day;
        top++;
    }
    return (long)count;
}
