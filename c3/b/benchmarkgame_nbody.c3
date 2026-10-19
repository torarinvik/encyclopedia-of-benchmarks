module benchmarkgame_nbody;
extern fn double sqrt(double x);
fn void put_f64(char* out, usz off, double value) { ulong bits=@bitcast(ulong,value); for(usz k=0;k<8;k++){out[off+k]=(char)(bits&255);bits>>=8;} }
struct Body { double x,y,z,vx,vy,vz,mass; }
fn double energy(Body* b) {
    double e=0.0;
    for(usz i=0;i<5;i++){e+=0.5*b[i].mass*(b[i].vx*b[i].vx+b[i].vy*b[i].vy+b[i].vz*b[i].vz);for(usz j=i+1;j<5;j++){double dx=b[i].x-b[j].x,dy=b[i].y-b[j].y,dz=b[i].z-b[j].z;double d=sqrt(dx*dx+dy*dy+dz*dz);e-=(b[i].mass*b[j].mass)/d;}}
    return e;
}
fn long benchmarkgame_nbody(long* input,usz length,char* output,usz capacity) @export("benchmarkgame_nbody") {
    if(input==null||length!=1||input[0]<0||input[0]>1000)return -1;
    if(output==null||capacity<16)return -2;
    double pi=3.141592653589793,solar=4*pi*pi,days=365.24;
    Body[5] b={
        {0,0,0,0,0,0,solar},
        {4.84143144246472090e+00,-1.16032004402742839e+00,-1.03622044471123109e-01,1.66007664274403694e-03*days,7.69901118419740425e-03*days,-6.90460016972063023e-05*days,9.54791938424326609e-04*solar},
        {8.34336671824457987e+00,4.12479856412430479e+00,-4.03523417114321381e-01,-2.76742510726862411e-03*days,4.99852801234917238e-03*days,2.30417297573763929e-05*days,2.85885980666130812e-04*solar},
        {1.28943695621391310e+01,-1.51111514016986312e+01,-2.23307578892655734e-01,2.96460137564761618e-03*days,2.37847173959480950e-03*days,-2.96589568540237556e-05*days,4.36624404335156298e-05*solar},
        {1.53796971148509165e+01,-2.59193146099879641e+01,1.79258772950371181e-01,2.68067772490389322e-03*days,1.62824170038242295e-03*days,-9.51592254519715870e-05*days,5.15138902046611451e-05*solar}
    };
    double px=0.0,py=0.0,pz=0.0;for(usz i=0;i<5;i++){px+=b[i].vx*b[i].mass;py+=b[i].vy*b[i].mass;pz+=b[i].vz*b[i].mass;}
    b[0].vx=-px/solar;b[0].vy=-py/solar;b[0].vz=-pz/solar;double initial=energy(&b[0]);
    for(long step=0;step<input[0];step++){for(usz i=0;i<5;i++)for(usz j=i+1;j<5;j++){double dx=b[i].x-b[j].x,dy=b[i].y-b[j].y,dz=b[i].z-b[j].z;double d=sqrt(dx*dx+dy*dy+dz*dz),mag=0.01/(d*d*d);b[i].vx-=dx*b[j].mass*mag;b[i].vy-=dy*b[j].mass*mag;b[i].vz-=dz*b[j].mass*mag;b[j].vx+=dx*b[i].mass*mag;b[j].vy+=dy*b[i].mass*mag;b[j].vz+=dz*b[i].mass*mag;}for(usz i=0;i<5;i++){b[i].x+=0.01*b[i].vx;b[i].y+=0.01*b[i].vy;b[i].z+=0.01*b[i].vz;}}
    double final=energy(&b[0]);put_f64(output,0,initial);put_f64(output,8,final);return 16;
}
