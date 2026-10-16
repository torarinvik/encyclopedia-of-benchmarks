fn feed(h0:u64,x:i64)u64{var h=h0;const u=@as(u64,@bitCast(x));for(0..8)|b|{h=(h^((u>>@intCast(8*b))&255))*%0x100000001b3;}return h;}
fn product(a:[3]i64,b:[3]i64,o:*[6]i64)void{o[0]+=a[0]*b[0];o[1]+=a[0]*b[1]+a[1]*b[0];o[2]+=a[0]*b[2]+a[2]*b[0];o[3]+=a[1]*b[1];o[4]+=a[1]*b[2]+a[2]*b[1];o[5]+=a[2]*b[2];}
export fn first_fundamental_form(v:[*]const i64,n:usize)i64{
 if(n!=18)return -1;for(0..18)|i|{if(v[i]<-100 or v[i]>100)return -1;}
 var ru:[3][3]i64=undefined;var rv:[3][3]i64=undefined;var e:[6]i64=@splat(0);var f:[6]i64=@splat(0);var g:[6]i64=@splat(0);
 for(0..3)|k|{const i=6*k;ru[k]=.{v[i+1],2*v[i+3],v[i+4]};rv[k]=.{v[i+2],v[i+4],2*v[i+5]};}
 for(0..3)|k|{product(ru[k],ru[k],&e);product(ru[k],rv[k],&f);product(rv[k],rv[k],&g);}
 var h:u64=0xcbf29ce484222325;for(e)|x|{h=feed(h,x);}for(f)|x|{h=feed(h,x);}for(g)|x|{h=feed(h,x);}return @bitCast(h);
}
