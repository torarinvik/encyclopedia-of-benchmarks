module boids_flocking_simulation;

const long MAX_BOIDS = 16;
const long SEPARATION_SCALE = 256;

fn long trunc_zero(long numerator, long denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

fn long ceil_sqrt(long value) {
    long low = 0, high = 4096;
    while (low < high) {
        long middle = (low + high) / 2;
        if (middle * middle < value) low = middle + 1;
        else high = middle;
    }
    return low;
}

fn void cap_vector(long x, long y, long limit, long* out_x, long* out_y) {
    long squared = x*x + y*y;
    if (squared <= limit*limit) { *out_x=x; *out_y=y; return; }
    if (limit == 0) { *out_x=0; *out_y=0; return; }
    long length=ceil_sqrt(squared);
    *out_x=trunc_zero(x*limit,length); *out_y=trunc_zero(y*limit,length);
}

fn void request_acceleration(usz index, usz count, long* x, long* y, long* vx, long* vy,
        long radius_squared, long max_acceleration, long* out_x, long* out_y) {
    long sx=0,sy=0,vxs=0,vys=0,ox=0,oy=0,neighbors=0;
    for (usz other=0;other<count;other++) {
        if (other==index) continue;
        long dx=x[other]-x[index],dy=y[other]-y[index],d2=dx*dx+dy*dy;
        if (d2>radius_squared) continue;
        neighbors++;
        if (d2==0) sx += index<other ? -SEPARATION_SCALE : SEPARATION_SCALE;
        else { long length=ceil_sqrt(d2); sx+=trunc_zero(-dx*SEPARATION_SCALE,length); sy+=trunc_zero(-dy*SEPARATION_SCALE,length); }
        vxs+=vx[other]; vys+=vy[other]; ox+=dx; oy+=dy;
    }
    if (neighbors==0) { *out_x=0; *out_y=0; return; }
    long rx[3]={0},ry[3]={0};
    cap_vector(trunc_zero(sx,neighbors),trunc_zero(sy,neighbors),max_acceleration,&rx[0],&ry[0]);
    cap_vector(trunc_zero(vxs,neighbors)-vx[index],trunc_zero(vys,neighbors)-vy[index],max_acceleration,&rx[1],&ry[1]);
    cap_vector(trunc_zero(ox,neighbors),trunc_zero(oy,neighbors),max_acceleration,&rx[2],&ry[2]);
    long ax=0,ay=0,used=0;
    for (usz rule=0;rule<3;rule++) {
        long remaining=max_acceleration-used;
        if (remaining<=0) break;
        long length=ceil_sqrt(rx[rule]*rx[rule]+ry[rule]*ry[rule]);
        if (length==0) continue;
        if (length<=remaining) { ax+=rx[rule]; ay+=ry[rule]; used+=length; }
        else { long tx,ty; cap_vector(rx[rule],ry[rule],remaining,&tx,&ty); ax+=tx; ay+=ty; break; }
    }
    *out_x=ax; *out_y=ay;
}

fn void store_i32(char* output, usz offset, long value) {
    uint bits=(uint)(int)value;
    for (usz byte=0;byte<4;byte++) output[offset+byte]=(char)((bits>>(byte*8))&255);
}

fn long boids_flocking_simulation(long* input, usz length, char* output, usz output_capacity) @export("boids_flocking_simulation") {
    if (input==null || length<9 || length>70) return -1;
    long n_value=input[0],steps=input[1],radius=input[2],max_speed=input[3],max_acceleration=input[4];
    if (n_value<1 || n_value>MAX_BOIDS || steps<0 || steps>16 || radius<0 || radius>128
        || max_speed<1 || max_speed>32 || max_acceleration<0 || max_acceleration>8
        || length!=5+4*(usz)n_value) return -1;
    usz n=(usz)n_value;
    long[MAX_BOIDS] x={0},y={0},vx={0},vy={0},nx={0},ny={0},nvx={0},nvy={0};
    for (usz i=0;i<n;i++) {
        x[i]=input[5+4*i]; y[i]=input[6+4*i]; vx[i]=input[7+4*i]; vy[i]=input[8+4*i];
        if (x[i]<-256 || x[i]>256 || y[i]<-256 || y[i]>256 || vx[i]<-32 || vx[i]>32
            || vy[i]<-32 || vy[i]>32 || vx[i]*vx[i]+vy[i]*vy[i]>max_speed*max_speed) return -1;
    }
    usz needed=16*n;
    if (output==null || output_capacity<needed) return -2;
    long radius_squared=radius*radius;
    for (long step=0;step<steps;step++) {
        for (usz i=0;i<n;i++) {
            long ax,ay;
            request_acceleration(i,n,&x[0],&y[0],&vx[0],&vy[0],radius_squared,max_acceleration,&ax,&ay);
            cap_vector(vx[i]+ax,vy[i]+ay,max_speed,&nvx[i],&nvy[i]);
            nx[i]=x[i]+nvx[i]; ny[i]=y[i]+nvy[i];
        }
        for (usz i=0;i<n;i++) { x[i]=nx[i]; y[i]=ny[i]; vx[i]=nvx[i]; vy[i]=nvy[i]; }
    }
    for (usz i=0;i<n;i++) { usz offset=16*i; store_i32(output,offset,x[i]); store_i32(output,offset+4,y[i]); store_i32(output,offset+8,vx[i]); store_i32(output,offset+12,vy[i]); }
    return (long)needed;
}
