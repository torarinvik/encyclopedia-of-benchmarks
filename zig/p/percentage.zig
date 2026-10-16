export fn percentage(v:[*c]const i64,n:usize)i64{
 if(v==null||n!=3||v[0]<1||v[0]>100000||v[1]<1||v[1]>100000||v[2]<1||v[2]>4)return -1;
 var scale:i64=1;for(0..@intCast(v[2])) |_|{scale*=10;}const product=v[0]*v[1]*scale;if(product<100)return -1;return @divTrunc(product,100);
}
