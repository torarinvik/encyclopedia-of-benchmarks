fn put64(out:[*]u8,i:usize,x:f64)void{const b:u64=@bitCast(x);for(0..8)|k|out[i*8+k]=@truncate(b>>@intCast(8*k));}
export fn euler_modified(v:?[*]const i64,n:usize,out:[*c]u8,cap:usize)i64{
 if(v==null or n!=2)return -1;const a=v.?;if(a[0]<1 or a[0]>8 or a[1]<1 or a[1]>4)return -1;const steps:usize=@intCast(a[0]);const bytes=(steps+1)*8;if(out==null or cap<bytes)return -2;
 const h:f64=0.25;var x:f64=0;var y:f64=@floatFromInt(a[1]);put64(out,0,y);
 for(0..steps)|i|{const f0=-2.0*x*y*y;const predictor=y+h*f0;const f1=-2.0*(x+h)*predictor*predictor;y=y+(h/2.0)*(f0+f1);x+=h;put64(out,i+1,y);}return @intCast(bytes);
}
