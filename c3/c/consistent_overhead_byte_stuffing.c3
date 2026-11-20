module consistent_overhead_byte_stuffing;

const usz MAX_WORDS = 257;
const usz MAX_PAYLOAD = 255;
const usz MAX_OUTPUT = 257;

fn long consistent_overhead_byte_stuffing(long* input, usz length,
        uchar* output, usz capacity) @export("consistent_overhead_byte_stuffing") {
    if (input == null || length < 1 || length > MAX_WORDS) return -1;
    long payload_value = input[0];
    if (payload_value < 0 || payload_value > (long)MAX_PAYLOAD) return -1;
    usz payload_length = (usz)payload_value;
    if (length != payload_length + 1) return -1;
    for (usz index = 0; index < payload_length; index++)
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;

    uchar[MAX_OUTPUT] staged;
    for (usz index = 0; index < MAX_OUTPUT; index++) staged[index] = 0;
    usz written = 1;
    usz code_position = 0;
    uint code = 1;
    bool omitted_terminal_code = false;
    for (usz index = 0; index < payload_length; index++) {
        uchar byte = (uchar)input[index + 1];
        if (byte == 0) {
            staged[code_position] = (uchar)code;
            code_position = written++;
            code = 1;
        } else {
            staged[written++] = byte;
            code++;
            if (code == 255) {
                staged[code_position] = 255;
                if (index + 1 == payload_length) {
                    omitted_terminal_code = true;
                    break;
                }
                code_position = written++;
                code = 1;
            }
        }
    }
    if (!omitted_terminal_code) staged[code_position] = (uchar)code;
    if (output == null || capacity < written) return -2;
    for (usz index = 0; index < written; index++) output[index] = staged[index];
    return (long)written;
}
