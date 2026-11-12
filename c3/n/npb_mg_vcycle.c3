module npb_mg_vcycle;

import "core:math";
extern fn double trunc(double value);

const int SIDE = 4;
const int CELLS = 64;
const int MAX_SOURCES = 8;

fn int wrap_index(int value, int side) {
    if (value < 0) return value + side;
    if (value >= side) return value - side;
    return value;
}
fn usz grid_index(int x, int y, int z, int side) {
    return (usz)(x + side * (y + side * z));
}
fn void stencil(double* src, double* dst, int side, double center, double face, double edge, double corner) {
    for (int z = 0; z < side; z++) for (int y = 0; y < side; y++) for (int x = 0; x < side; x++) {
        usz q = grid_index(x, y, z, side);
        double total = center * src[q];
        for (int dz = -1; dz <= 1; dz++) for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
            int distance = (dx < 0 ? -dx : dx) + (dy < 0 ? -dy : dy) + (dz < 0 ? -dz : dz);
            if (distance == 0) continue;
            double weight = distance == 1 ? face : (distance == 2 ? edge : corner);
            usz neighbor = grid_index(wrap_index(x + dx, side), wrap_index(y + dy, side), wrap_index(z + dz, side), side);
            total = total + weight * src[neighbor];
        }
        dst[q] = total;
    }
}
fn void restrict_grid(double* fine, int side, double* coarse) {
    int half = side / 2;
    for (int z = 0; z < half; z++) for (int y = 0; y < half; y++) for (int x = 0; x < half; x++) {
        double total = 0.0;
        for (int dz = -1; dz <= 1; dz++) for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
            double wx = dx == 0 ? 1.0 : 0.5;
            double wy = dy == 0 ? 1.0 : 0.5;
            double wz = dz == 0 ? 1.0 : 0.5;
            usz q = grid_index(wrap_index(2*x+dx, side), wrap_index(2*y+dy, side), wrap_index(2*z+dz, side), side);
            total = total + wx * wy * wz * fine[q];
        }
        coarse[grid_index(x, y, z, half)] = 0.5 * total;
    }
}
fn void interpolate_grid(double* coarse, int half, double* fine) {
    int side = 2 * half;
    for (int z = 0; z < side; z++) for (int y = 0; y < side; y++) for (int x = 0; x < side; x++) {
        int bx=x/2, by=y/2, bz=z/2;
        int nx=(x&1)?2:1, ny=(y&1)?2:1, nz=(z&1)?2:1;
        double wx=(x&1)?0.5:1.0, wy=(y&1)?0.5:1.0, wz=(z&1)?0.5:1.0;
        double total=0.0;
        for (int iz=0; iz<nz; iz++) for (int iy=0; iy<ny; iy++) for (int ix=0; ix<nx; ix++) {
            total = total + wx*wy*wz*coarse[grid_index((bx+ix)%half,(by+iy)%half,(bz+iz)%half,half)];
        }
        fine[grid_index(x,y,z,side)] = total;
    }
}
fn void vcycle(double* rhs, int side, double* solution) {
    if (side == 2) { stencil(rhs, solution, side, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0); return; }
    int half=side/2;
    double coarse_rhs[CELLS]={0.0}, coarse_solution[CELLS]={0.0};
    double prolonged[CELLS]={0.0}, applied[CELLS]={0.0}, remaining[CELLS]={0.0}, post[CELLS]={0.0};
    restrict_grid(rhs,side,&coarse_rhs[0]);
    vcycle(&coarse_rhs[0],half,&coarse_solution[0]);
    interpolate_grid(&coarse_solution[0],half,&prolonged[0]);
    stencil(&prolonged[0],&applied[0],side,-8.0/3.0,0.0,1.0/6.0,1.0/12.0);
    usz count=(usz)(side*side*side);
    for(usz q=0;q<count;q++) remaining[q]=rhs[q]-applied[q];
    stencil(&remaining[0],&post[0],side,-3.0/8.0,1.0/32.0,-1.0/64.0,0.0);
    for(usz q=0;q<count;q++) solution[q]=prolonged[q]+post[q];
}

fn long npb_mg_vcycle(double* input, usz length, double* output, usz capacity) @export("npb_mg_vcycle") {
    if (input == null || length < 2 || length > 34) return -1;
    double itv=input[0], countv=input[1];
    if (itv != itv || trunc(itv) != itv || itv < 1 || itv > 4 || countv != countv || trunc(countv) != countv || countv < 0 || countv > MAX_SOURCES) return -1;
    int iterations=(int)itv, sources=(int)countv;
    if (length != (usz)(2+4*sources)) return -1;
    double rhs[CELLS]={0.0}; bool seen[CELLS]={false};
    for(int s=0;s<sources;s++) {
        usz base=(usz)(2+4*s); double xv=input[base], yv=input[base+1], zv=input[base+2], value=input[base+3];
        if (xv != xv || yv != yv || zv != zv || value != value || trunc(xv)!=xv || trunc(yv)!=yv || trunc(zv)!=zv || xv<0 || xv>=SIDE || yv<0 || yv>=SIDE || zv<0 || zv>=SIDE || value < -4 || value > 4) return -1;
        usz q=grid_index((int)xv,(int)yv,(int)zv,SIDE);
        if (seen[q]) return -1;
        seen[q]=true; rhs[q]=value;
    }
    if (output == null || capacity < 1) return -2;
    double solution[CELLS]={0.0}, applied[CELLS]={0.0}, residual[CELLS]={0.0}, correction[CELLS]={0.0};
    for(int iteration=0;iteration<iterations;iteration++) {
        stencil(&solution[0],&applied[0],SIDE,-8.0/3.0,0.0,1.0/6.0,1.0/12.0);
        for(usz q=0;q<CELLS;q++) residual[q]=rhs[q]-applied[q];
        vcycle(&residual[0],SIDE,&correction[0]);
        for(usz q=0;q<CELLS;q++) solution[q]=solution[q]+correction[q];
    }
    double checksum=0.0; for(usz q=0;q<CELLS;q++) checksum=checksum+solution[q];
    output[0]=checksum; return 1;
}
