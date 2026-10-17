module sierpinski_triangle;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn void emit_segment(char* output, usz* position, long x0, long y0, long x1, long y1) {
    write_i64_le(output, *position, x0); *position += 8;
    write_i64_le(output, *position, y0); *position += 8;
    write_i64_le(output, *position, x1); *position += 8;
    write_i64_le(output, *position, y1); *position += 8;
}

fn void draw_triangle(char* output, usz* position, long x1, long y1, long x2, long y2,
                      long x3, long y3, long depth) {
    emit_segment(output, position, x1, y1, x2, y2);
    emit_segment(output, position, x2, y2, x3, y3);
    emit_segment(output, position, x3, y3, x1, y1);
    if (depth == 0) return;
    long abx = (x1 + x2) / 2, aby = (y1 + y2) / 2;
    long acx = (x1 + x3) / 2, acy = (y1 + y3) / 2;
    long bcx = (x2 + x3) / 2, bcy = (y2 + y3) / 2;
    draw_triangle(output, position, x1, y1, abx, aby, acx, acy, depth - 1);
    draw_triangle(output, position, x2, y2, abx, aby, bcx, bcy, depth - 1);
    draw_triangle(output, position, x3, y3, bcx, bcy, acx, acy, depth - 1);
}

fn long sierpinski_triangle(long* input, usz length, char* output, usz capacity) @export("sierpinski_triangle") {
    if (input == null || length != 1) return -1;
    long depth = input[0];
    if (depth < 0 || depth > 4) return -1;
    usz calls = 1;
    for (long level = 0; level < depth; level++) calls = calls * 3 + 1;
    usz needed = calls * 96;
    if (needed > 11616) return -1;
    if (output == null || capacity < needed) return -2;
    usz position = 0;
    draw_triangle(output, &position, -2800, -2000, 0, 2800, 2800, -2000, depth);
    return (long)needed;
}
