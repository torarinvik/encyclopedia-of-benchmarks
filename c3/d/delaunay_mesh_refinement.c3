module delaunay_mesh_refinement;
import "math";

const usz INPUT_LENGTH = 7;
const usz MAX_OUTPUT_BYTES = 152;
const long COORDINATE_SCALE = 1000000;

fn long orient(long ax, long ay, long bx, long by, long cx, long cy) {
    return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax);
}
fn long round_ratio_away(long numerator, long denominator) {
    long magnitude = numerator < 0 ? -numerator : numerator;
    long rounded = (magnitude + denominator/2) / denominator;
    return numerator < 0 ? -rounded : rounded;
}
fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset+byte] = (char)(bits & 255); bits >>= 8; }
}

fn long delaunay_mesh_refinement(long* values, usz length, char* output, usz capacity) @export("delaunay_mesh_refinement") {
    if (values == null || length != INPUT_LENGTH || values[0] != 3) return -1;
    long[3] x = {}; long[3] y = {};
    for (int i = 0; i < 3; i++) {
        x[i] = values[1+2*i]; y[i] = values[2+2*i];
        if (x[i] < -100 || x[i] > 100 || y[i] < -100 || y[i] > 100) return -1;
        for (int j = 0; j < i; j++) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    long area2 = orient(x[0], y[0], x[1], y[1], x[2], y[2]);
    if (area2 <= 0) return -1;
    for (int i = 0; i < 3; i++) {
        int j = (i+1)%3, k = (i+2)%3;
        long ux = x[j]-x[i], uy = y[j]-y[i], vx = x[k]-x[i], vy = y[k]-y[i];
        if (ux*vx+uy*vy <= 0) return -1;
    }
    double len01 = math.sqrt((double)((x[1]-x[0])*(x[1]-x[0]) + (y[1]-y[0])*(y[1]-y[0])));
    double len12 = math.sqrt((double)((x[2]-x[1])*(x[2]-x[1]) + (y[2]-y[1])*(y[2]-y[1])));
    double len20 = math.sqrt((double)((x[0]-x[2])*(x[0]-x[2]) + (y[0]-y[2])*(y[0]-y[2])));
    double shortest = len01 < len12 ? (len01 < len20 ? len01 : len20) : (len12 < len20 ? len12 : len20);
    double ratio = (len01*len12*len20)/(2.0*(double)area2*shortest);
    double beta = 1.0/(2.0*math.sin(3.14159265358979323846/9.0));
    bool refine = ratio > beta*(1.0+1e-12);
    char[152] staged = {};
    put_i64(staged, 0, refine ? 4 : 3);
    for (int i = 0; i < 3; i++) { put_i64(staged, 8+16*(usz)i, x[i]*COORDINATE_SCALE); put_i64(staged, 16+16*(usz)i, y[i]*COORDINATE_SCALE); }
    if (refine) {
        long ax=x[0], ay=y[0], bax=x[1]-ax, bay=y[1]-ay, cax=x[2]-ax, cay=y[2]-ay;
        long denominator=2*(bax*cay-bay*cax), balen_sq=bax*bax+bay*bay, calen_sq=cax*cax+cay*cay;
        long center_x_num=ax*denominator+cay*balen_sq-bay*calen_sq;
        long center_y_num=ay*denominator+bax*calen_sq-cax*balen_sq;
        put_i64(staged, 56, round_ratio_away(center_x_num*COORDINATE_SCALE, denominator));
        put_i64(staged, 64, round_ratio_away(center_y_num*COORDINATE_SCALE, denominator));
        long[10] words = {3,0,1,3,1,2,3,2,0,3};
        for (int i=0;i<10;i++) put_i64(staged,72+8*(usz)i,words[i]);
    } else {
        long[4] words = {1,0,1,2};
        for (int i=0;i<4;i++) put_i64(staged,56+8*(usz)i,words[i]);
    }
    usz required = refine ? MAX_OUTPUT_BYTES : 88;
    if (output == null || capacity < required) return -2;
    for (usz i=0;i<required;i++) output[i]=staged[i];
    return (long)required;
}
