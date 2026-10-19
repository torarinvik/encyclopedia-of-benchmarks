// Independent bounded port of the classic five-body solar-system kernel.
const Body = struct { x:f64,y:f64,z:f64,vx:f64,vy:f64,vz:f64,mass:f64 };
fn putF64(outp:[*]u8,offset:usize,value:f64) void { const bits=@as(u64,@bitCast(value)); for(0..8)|k| outp[offset+k]=@truncate(bits>>(8*k)); }
fn energy(b:*const [5]Body) f64 { var e:f64=0;for(0..5)|i|{e+=0.5*b[i].mass*(b[i].vx*b[i].vx+b[i].vy*b[i].vy+b[i].vz*b[i].vz);var j=i+1;while(j<5):(j+=1){const dx=b[i].x-b[j].x;const dy=b[i].y-b[j].y;const dz=b[i].z-b[j].z;const d=@sqrt(dx*dx+dy*dy+dz*dz);e-=(b[i].mass*b[j].mass)/d;}}return e; }
export fn benchmarkgame_nbody(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length!=1)return -1;const steps=input[0];if(steps<0 or steps>1000)return -1;if(output==null or capacity<16)return -2;
 const pi=3.141592653589793;const solar=4.0*pi*pi;const days=365.24;
 var b=[_]Body{
 .{.x=0,.y=0,.z=0,.vx=0,.vy=0,.vz=0,.mass=solar},
 .{.x=4.84143144246472090e+00,.y=-1.16032004402742839e+00,.z=-1.03622044471123109e-01,.vx=1.66007664274403694e-03*days,.vy=7.69901118419740425e-03*days,.vz=-6.90460016972063023e-05*days,.mass=9.54791938424326609e-04*solar},
 .{.x=8.34336671824457987e+00,.y=4.12479856412430479e+00,.z=-4.03523417114321381e-01,.vx=-2.76742510726862411e-03*days,.vy=4.99852801234917238e-03*days,.vz=2.30417297573763929e-05*days,.mass=2.85885980666130812e-04*solar},
 .{.x=1.28943695621391310e+01,.y=-1.51111514016986312e+01,.z=-2.23307578892655734e-01,.vx=2.96460137564761618e-03*days,.vy=2.37847173959480950e-03*days,.vz=-2.96589568540237556e-05*days,.mass=4.36624404335156298e-05*solar},
 .{.x=1.53796971148509165e+01,.y=-2.59193146099879641e+01,.z=1.79258772950371181e-01,.vx=2.68067772490389322e-03*days,.vy=1.62824170038242295e-03*days,.vz=-9.51592254519715870e-05*days,.mass=5.15138902046611451e-05*solar},
 };
 var px:f64=0;var py:f64=0;var pz:f64=0;for(0..5)|i|{px+=b[i].vx*b[i].mass;py+=b[i].vy*b[i].mass;pz+=b[i].vz*b[i].mass;}b[0].vx=-px/solar;b[0].vy=-py/solar;b[0].vz=-pz/solar;const initial=energy(&b);
 for(0..@intCast(steps)) |_| { for(0..5)|i|{var j=i+1;while(j<5):(j+=1){const dx=b[i].x-b[j].x;const dy=b[i].y-b[j].y;const dz=b[i].z-b[j].z;const d=@sqrt(dx*dx+dy*dy+dz*dz);const mag=0.01/(d*d*d);b[i].vx-=dx*b[j].mass*mag;b[i].vy-=dy*b[j].mass*mag;b[i].vz-=dz*b[j].mass*mag;b[j].vx+=dx*b[i].mass*mag;b[j].vy+=dy*b[i].mass*mag;b[j].vz+=dz*b[i].mass*mag;}}for(0..5)|i|{b[i].x+=0.01*b[i].vx;b[i].y+=0.01*b[i].vy;b[i].z+=0.01*b[i].vz;}}
 putF64(output,0,initial);putF64(output,8,energy(&b));return 16;
}
