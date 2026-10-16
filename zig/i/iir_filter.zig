fn put64(o:[*]u8,i:usize,x:f64)void{const b:u64=@bitCast(x);for(0..8)|k|o[i*8+k]=@truncate(b>>@intCast(8*k));}
export fn iir_filter(v:?[*]const i64,n:usize,out:[*c]u8,cap:usize)i64{
 if(v==null or n<7 or n>26)return -1;const a0=v.?;if(a0[0]<1 or a0[0]>3 or a0[1]<1 or a0[1]>16)return -1;const order:usize=@intCast(a0[0]);const samples:usize=@intCast(a0[1]);if(n!=4+2*order+samples)return -1;
 var a=[_]f64{0}**4;var b=[_]f64{0}**4;var xh=[_]f64{0}**3;var yh=[_]f64{0}**3;for(0..order+1)|i|{const av=a0[2+i];const bv=a0[3+order+i];if(av < -500 or av>2000 or bv < -500 or bv>500)return -1;a[i]=@as(f64,@floatFromInt(av))/1000.0;b[i]=@as(f64,@floatFromInt(bv))/1000.0;}if(a[0]<0.5)return -1;for(0..samples)|i|{const x=a0[4+2*order+i];if(x < -1000 or x>1000)return -1;}
 const bytes=samples*8;if(out==null or cap<bytes)return -2;for(0..samples)|s|{const x=@as(f64,@floatFromInt(a0[4+2*order+s]))/1000.0;var y:f64=0;for(1..order+1)|i|{y+=b[i]*xh[i-1]-a[i]*yh[i-1];}y=(y+b[0]*x)/a[0];var i=order;while(i>1){i-=1;xh[i]=xh[i-1];yh[i]=yh[i-1];}xh[0]=x;yh[0]=y;put64(out,s,y);}return @intCast(bytes);
}
