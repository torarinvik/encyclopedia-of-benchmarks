// Independent bounded port of the classic five-body solar-system kernel.
#[derive(Clone, Copy)]
struct Body { x:f64,y:f64,z:f64,vx:f64,vy:f64,vz:f64,mass:f64 }
fn energy(b:&[Body;5])->f64{let mut e=0.0;for i in 0..5{e+=0.5*b[i].mass*(b[i].vx*b[i].vx+b[i].vy*b[i].vy+b[i].vz*b[i].vz);for j in i+1..5{let dx=b[i].x-b[j].x;let dy=b[i].y-b[j].y;let dz=b[i].z-b[j].z;let d=(dx*dx+dy*dy+dz*dz).sqrt();e-=(b[i].mass*b[j].mass)/d;}}e}
fn put_f64(out:*mut u8,offset:usize,value:f64){let bytes=value.to_le_bytes();unsafe{for k in 0..8{*out.add(offset+k)=bytes[k];}}}
#[no_mangle]
pub unsafe extern "C" fn benchmarkgame_nbody(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length!=1{return -1}let steps=unsafe{*input};if !(0..=1000).contains(&steps){return -1}if output.is_null()||capacity<16{return -2}
 let pi=3.141592653589793;let solar=4.0*pi*pi;let days=365.24;
 let mut b=[Body{x:0.0,y:0.0,z:0.0,vx:0.0,vy:0.0,vz:0.0,mass:solar},
 Body{x:4.84143144246472090e+00,y:-1.16032004402742839e+00,z:-1.03622044471123109e-01,vx:1.66007664274403694e-03*days,vy:7.69901118419740425e-03*days,vz:-6.90460016972063023e-05*days,mass:9.54791938424326609e-04*solar},
 Body{x:8.34336671824457987e+00,y:4.12479856412430479e+00,z:-4.03523417114321381e-01,vx:-2.76742510726862411e-03*days,vy:4.99852801234917238e-03*days,vz:2.30417297573763929e-05*days,mass:2.85885980666130812e-04*solar},
 Body{x:1.28943695621391310e+01,y:-1.51111514016986312e+01,z:-2.23307578892655734e-01,vx:2.96460137564761618e-03*days,vy:2.37847173959480950e-03*days,vz:-2.96589568540237556e-05*days,mass:4.36624404335156298e-05*solar},
 Body{x:1.53796971148509165e+01,y:-2.59193146099879641e+01,z:1.79258772950371181e-01,vx:2.68067772490389322e-03*days,vy:1.62824170038242295e-03*days,vz:-9.51592254519715870e-05*days,mass:5.15138902046611451e-05*solar}];
 let(mut px,mut py,mut pz)=(0.0,0.0,0.0);for i in 0..5{px+=b[i].vx*b[i].mass;py+=b[i].vy*b[i].mass;pz+=b[i].vz*b[i].mass;}b[0].vx=-px/solar;b[0].vy=-py/solar;b[0].vz=-pz/solar;let initial=energy(&b);
 for _ in 0..steps{for i in 0..5{for j in i+1..5{let dx=b[i].x-b[j].x;let dy=b[i].y-b[j].y;let dz=b[i].z-b[j].z;let d=(dx*dx+dy*dy+dz*dz).sqrt();let mag=0.01/(d*d*d);b[i].vx-=dx*b[j].mass*mag;b[i].vy-=dy*b[j].mass*mag;b[i].vz-=dz*b[j].mass*mag;b[j].vx+=dx*b[i].mass*mag;b[j].vy+=dy*b[i].mass*mag;b[j].vz+=dz*b[i].mass*mag;}}for i in 0..5{b[i].x+=0.01*b[i].vx;b[i].y+=0.01*b[i].vy;b[i].z+=0.01*b[i].vz;}}
 unsafe{put_f64(output,0,initial);put_f64(output,8,energy(&b));}16
}
