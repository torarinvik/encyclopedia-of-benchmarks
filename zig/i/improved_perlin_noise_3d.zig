/// Fixed-table improved Perlin gradient noise for one bounded 3D point.
const permutation = [256]i32{
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,
    140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,
    247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,
    57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,
    74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,
    60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,
    65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
    200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,
    52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,
    207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,
    119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
    129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
    218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,
    81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,
    184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
    222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
};

fn lookup(index: i32) i32 { return permutation[@intCast(index & 255)]; }
fn fade(t: f64) f64 { return t*t*t*(t*(t*6.0-15.0)+10.0); }
fn mix(t: f64, a: f64, b: f64) f64 { return a+t*(b-a); }
fn gradient(hash: i32, x: f64, y: f64, z: f64) f64 {
    const k=hash&15;
    const u=if(k<8)x else y;
    const v=if(k<4)y else if(k==12 or k==14)x else z;
    return (if(k&1==0)u else -u)+(if(k&2==0)v else -v);
}

export fn improved_perlin_noise_3d(x_input: f64, y_input: f64, z_input: f64) f64 {
    if (x_input!=x_input or y_input!=y_input or z_input!=z_input or
        x_input < -1_000_000.0 or x_input > 1_000_000.0 or
        y_input < -1_000_000.0 or y_input > 1_000_000.0 or
        z_input < -1_000_000.0 or z_input > 1_000_000.0) return -1.0;
    const fx=@floor(x_input);const fy=@floor(y_input);const fz=@floor(z_input);
    const ix=@as(i32,@intFromFloat(fx))&255;const iy=@as(i32,@intFromFloat(fy))&255;const iz=@as(i32,@intFromFloat(fz))&255;
    const x=x_input-fx;const y=y_input-fy;const z=z_input-fz;
    const u=fade(x);const v=fade(y);const w=fade(z);
    const a=lookup(ix)+iy;const aa=lookup(a)+iz;const ab=lookup(a+1)+iz;
    const b=lookup(ix+1)+iy;const ba=lookup(b)+iz;const bb=lookup(b+1)+iz;
    return mix(w,
        mix(v,mix(u,gradient(lookup(aa),x,y,z),gradient(lookup(ba),x-1.0,y,z)),
                mix(u,gradient(lookup(ab),x,y-1.0,z),gradient(lookup(bb),x-1.0,y-1.0,z))),
        mix(v,mix(u,gradient(lookup(aa+1),x,y,z-1.0),gradient(lookup(ba+1),x-1.0,y,z-1.0)),
                mix(u,gradient(lookup(ab+1),x,y-1.0,z-1.0),gradient(lookup(bb+1),x-1.0,y-1.0,z-1.0))));
}
