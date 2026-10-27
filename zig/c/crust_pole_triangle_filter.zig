const MAX_FACETS:usize=16;const MAX_VERTICES:usize=12;
fn lessTri(a:[3]i64,b:[3]i64)bool{for(0..3)|i|{if(a[i]<b[i])return true;if(a[i]>b[i])return false;}return false;}
fn equalTri(a:[3]i64,b:[3]i64)bool{return a[0]==b[0] and a[1]==b[1] and a[2]==b[2];}
fn putI64(out:[*c]u8,word:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[word*8+b]=@truncate(bits>>@intCast(8*b));}
export fn crust_pole_triangle_filter(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null||length<3||length>51)return -1;const ns0=input[0];const np0=input[1];const nf0=input[2];
    if(ns0<3||ns0>8||np0<1||np0>4||ns0+np0>MAX_VERTICES||nf0<0||nf0>MAX_FACETS||length!=3+3*@as(usize,@intCast(nf0)))return -1;
    const ns:usize=@intCast(ns0);const total:usize=@intCast(ns0+np0);const nf:usize=@intCast(nf0);var facets=[_] [3]i64{.{0,0,0}} ** MAX_FACETS;var count:usize=0;
    for(0..nf)|i|{var tri=[_]i64{input[3+3*i],input[4+3*i],input[5+3*i]};if(tri[0]<0 or tri[0]>=total or tri[1]<0 or tri[1]>=total or tri[2]<0 or tri[2]>=total or tri[0]==tri[1] or tri[0]==tri[2] or tri[1]==tri[2])return -1;if(tri[0]>=ns or tri[1]>=ns or tri[2]>=ns)continue;
      for(1..3)|a|{const x=tri[a];var j=a;while(j>0 and tri[j-1]>x):(j-=1){tri[j]=tri[j-1];}tri[j]=x;}var duplicate=false;for(0..count)|j|{if(equalTri(tri,facets[j]))duplicate=true;}if(!duplicate){facets[count]=tri;count+=1;}
    }
    for(1..count)|i|{const x=facets[i];var j=i;while(j>0 and lessTri(x,facets[j-1])):(j-=1){facets[j]=facets[j-1];}facets[j]=x;}
    const bytes=(1+3*count)*8;if(output==null or capacity<bytes)return -2;putI64(output,0,@intCast(count));var at:usize=1;for(0..count)|i|{for(0..3)|j|{putI64(output,at,facets[i][j]);at+=1;}}return @intCast(bytes);
}
