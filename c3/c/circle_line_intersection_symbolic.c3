// Independently authored draft; not compiled or run.
module circle_line_intersection_symbolic;
fn long circle_line_intersection_symbolic(long* input, usz length, char* output, usz capacity)
        @export("circle_line_intersection_symbolic") {
    if (input == null || length != 6) return -1;
    for (usz i = 0; i < 6; i++) if (input[i] < -1000 || input[i] > 1000) return -1;
    long x=input[0], y=input[1], r=input[2], a=input[3], b=input[4], c=input[5];
    if (r < 1 || (a == 0 && b == 0)) return -1;
    long d=a*a+b*b, q=a*x+b*y+c, h=r*r*d-q*q;
    long[7] words = {h < 0 ? 0 : h == 0 ? 1 : 2, x*d-a*q, y*d-b*q, d, -b, a, h};
    usz count = h < 0 ? 1 : 7, needed = 8 * count;
    if (output == null || capacity < needed) return -2;
    for (usz i = 0; i < count; i++) {
        ulong bits = (ulong)words[i];
        for (usz j = 0; j < 8; j++) { output[8*i+j] = (char)(bits & 255); bits >>= 8; }
    }
    return (long)needed;
}
