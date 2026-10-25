module parboil_lbm;

extern fn float roundf(float value);

const int Q = 19;
const int CELLS = 27;
const int W = 3;
const int HW = 5;
const int[19] DX = {0,0,0,1,-1,0,0,1,-1,1,-1,0,0,0,0,1,1,-1,-1};
const int[19] DY = {0,1,-1,0,0,0,0,1,1,-1,-1,1,1,-1,-1,0,0,0,0};
const int[19] DZ = {0,0,0,0,0,1,-1,0,0,0,0,1,-1,1,-1,1,-1,1,-1};
const int[19] OPP = {0,2,1,4,3,6,5,10,9,8,7,14,13,12,11,18,17,16,15};

fn int cell_index(int x, int y, int z) { return x + 3*y + 9*z; }
fn int halo_index(int x, int y, int z, int q) { return (((z+1)*5+(y+1))*5+(x+1))*Q+q; }
fn float initial_weight(int q) {
    if (q == 0) return (float)(1.0 / 3.0);
    if (q <= 6) return (float)(1.0 / 18.0);
    return (float)(1.0 / 36.0);
}
fn float axis_factor(float u, bool positive, float u2) {
    float product = 4.5f * u;
    product = positive ? product + 3.0f : product - 3.0f;
    product = u * product;
    product = 1.0f + product;
    return product - u2;
}
fn float diagonal_factor(float cu, float u2) {
    float product = 4.5f * cu;
    product = product + 3.0f;
    product = cu * product;
    product = 1.0f + product;
    return product - u2;
}
fn float collide(float source, float rho, float factor, double weight) {
    float omega = 1.95f;
    float base = (1.0f - omega) * source;
    double equilibrium = weight * omega;
    equilibrium = equilibrium * rho;
    equilibrium = equilibrium * factor;
    return (float)((double)base + equilibrium);
}
fn void collide_cell(float* f, float* post) {
    float rho = f[0];
    for (int q = 1; q < Q; q++) rho = rho + f[q];
    float ux = f[3]; ux = ux-f[4]; ux=ux+f[7]; ux=ux-f[8]; ux=ux+f[9]; ux=ux-f[10]; ux=ux+f[15]; ux=ux+f[16]; ux=ux-f[17]; ux=ux-f[18];
    float uy = f[1]; uy=uy-f[2]; uy=uy+f[7]; uy=uy+f[8]; uy=uy-f[9]; uy=uy-f[10]; uy=uy+f[11]; uy=uy+f[12]; uy=uy-f[13]; uy=uy-f[14];
    float uz = f[5]; uz=uz-f[6]; uz=uz+f[11]; uz=uz-f[12]; uz=uz+f[13]; uz=uz-f[14]; uz=uz+f[15]; uz=uz-f[16]; uz=uz+f[17]; uz=uz-f[18];
    ux=ux/rho; uy=uy/rho; uz=uz/rho;
    float u2=ux*ux; u2=u2+uy*uy; u2=u2+uz*uz; u2=1.5f*u2;
    post[0]=collide(f[0],rho,1.0f-u2,1.0/3.0);
    post[1]=collide(f[1],rho,axis_factor(uy,true,u2),1.0/18.0); post[2]=collide(f[2],rho,axis_factor(uy,false,u2),1.0/18.0);
    post[3]=collide(f[3],rho,axis_factor(ux,true,u2),1.0/18.0); post[4]=collide(f[4],rho,axis_factor(ux,false,u2),1.0/18.0);
    post[5]=collide(f[5],rho,axis_factor(uz,true,u2),1.0/18.0); post[6]=collide(f[6],rho,axis_factor(uz,false,u2),1.0/18.0);
    float cu=ux+uy; post[7]=collide(f[7],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-ux+uy; post[8]=collide(f[8],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=ux-uy; post[9]=collide(f[9],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-ux-uy; post[10]=collide(f[10],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=uy+uz; post[11]=collide(f[11],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=uy-uz; post[12]=collide(f[12],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-uy+uz; post[13]=collide(f[13],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-uy-uz; post[14]=collide(f[14],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=ux+uz; post[15]=collide(f[15],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=ux-uz; post[16]=collide(f[16],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-ux+uz; post[17]=collide(f[17],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-ux-uz; post[18]=collide(f[18],rho,diagonal_factor(cu,u2),1.0/36.0);
}

fn long parboil_lbm(long* values, usz length) @export("parboil_lbm") {
    if (values == null || length != 19) return -1;
    bool nonzero = false;
    for (int q=0; q<Q; q++) { if (values[q] < 0 || values[q] > 100000) return -1; if (values[q] != 0) nonzero=true; }
    if (!nonzero) return -1;
    float[CELLS*Q] source = {};
    float[HW*HW*HW*Q] destination = {};
    for (int z=0; z<W; z++) for (int y=0; y<W; y++) for (int x=0; x<W; x++) {
        int cell=cell_index(x,y,z);
        for (int q=0; q<Q; q++) { source[cell*Q+q]=initial_weight(q); destination[halo_index(x,y,z,q)]=initial_weight(q); }
    }
    for (int q=0; q<Q; q++) source[cell_index(1,1,1)*Q+q]=(float)values[q]/1000000.0f;
    for (int z=0; z<W; z++) for (int y=0; y<W; y++) for (int x=0; x<W; x++) {
        int cell=cell_index(x,y,z);
        bool obstacle=x==0||x==2||y==0||y==2||z==0||z==2;
        float[Q] post = {};
        if (!obstacle) collide_cell(&source[cell*Q],&post[0]);
        for (int q=0; q<Q; q++) {
            float outgoing;
            if (obstacle) outgoing = source[cell*Q+OPP[q]];
            else outgoing = post[q];
            destination[halo_index(x+DX[q],y+DY[q],z+DZ[q],q)]=outgoing;
        }
    }
    long checksum=0;
    for (int z=0; z<W; z++) for (int y=0; y<W; y++) for (int x=0; x<W; x++) {
        int cell=cell_index(x,y,z);
        for (int q=0; q<Q; q++) checksum += (long)(cell+1)*(long)roundf(destination[halo_index(x,y,z,q)]*1000000.0f);
    }
    return checksum;
}
