fn put64(out: [*]u8, i: usize, value: i64) void { const u: u64 = @bitCast(value); for (0..8) |b| out[i*8+b] = @truncate(u >> @intCast(8*b)); }
pub export fn rodinia_streamcluster_pgain(values: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const v=values orelse return -1; if(length<5 or length>53)return -1;
    const pn=v[0];const dd=v[1];const xx=v[2];const z=v[3];const mask=v[4];
    if(pn<2 or pn>8 or dd<1 or dd>3 or length!=5+@as(usize,@intCast(pn))*(3+@as(usize,@intCast(dd))) or xx<0 or xx>=pn or z<1 or z>64 or mask<=0 or @as(u64,@intCast(mask))>=(@as(u64,1)<<@intCast(pn)) or (mask&(@as(i64,1)<<@intCast(xx)))!=0)return -1;
    const p:usize=@intCast(pn);const d:usize=@intCast(dd);const x:usize=@intCast(xx);var q:usize=5;var a=[_]usize{0}**8;var w=[_]i64{0}**8;var c=[_]i64{0}**8;var pt=[_] [3]i64{.{0,0,0}}**8;
    for(0..p)|i|{if(v[q]<0 or v[q]>=pn)return -1;a[i]=@intCast(v[q]);q+=1;if((mask&(@as(i64,1)<<@intCast(a[i])))==0)return -1;}
    for(0..p)|i|{if(v[q]<1 or v[q]>4)return -1;w[i]=v[q];q+=1;}for(0..p)|i|{c[i]=v[q];q+=1;}for(0..p)|i|for(0..d)|k|{if(v[q]<-8 or v[q]>8)return -1;pt[i][k]=v[q];q+=1;};
    for(0..p)|i|{var ds:i64=0;for(0..d)|k|{const t=pt[i][k]-pt[a[i]][k];ds+=t*t;}if(c[i]!=w[i]*ds or ((mask&(@as(i64,1)<<@intCast(i)))!=0 and (a[i]!=i or c[i]!=0)))return -1;}
    var sw=[_]bool{false}**8;var low=[_]i64{0}**8;var cl=[_]bool{false}**8;var opening=z;
    for(0..p)|i|{var ds:i64=0;for(0..d)|k|{const t=pt[i][k]-pt[x][k];ds+=t*t;}const xc=w[i]*ds;if(xc<c[i]){sw[i]=true;opening+=xc-c[i];}else low[a[i]]+=c[i]-xc;}
    for(0..p)|j|if((mask&(@as(i64,1)<<@intCast(j)))!=0){const lo=z+low[j];if(lo>0){cl[j]=true;opening-=lo;}};
    const yes=opening<0;var om=mask;var oa=a;var oc=c;if(yes){for(0..p)|i|if(sw[i] or cl[a[i]]){var ds:i64=0;for(0..d)|k|{const t=pt[i][k]-pt[x][k];ds+=t*t;}oa[i]=x;oc[i]=w[i]*ds;};for(0..p)|j|if(cl[j]){om&=~(@as(i64,1)<<@intCast(j));};om|=@as(i64,1)<<@intCast(x);}
    var count:i64=0;var obj:i64=0;for(0..p)|j|if((om&(@as(i64,1)<<@intCast(j)))!=0){count+=1;};obj=count*z;for(0..p)|i|obj+=oc[i];const out=output orelse return -2;if(capacity<8*(5+2*p))return -2;var r=[_]i64{0}**21;r[0]=@intFromBool(yes);r[1]=if(yes)-opening else 0;r[2]=count;r[3]=om;r[4]=obj;for(0..p)|i|{r[5+i]=@intCast(oa[i]);r[5+p+i]=oc[i];}for(0..5+2*p)|i|put64(out,i,r[i]);return @intCast(5+2*p);
}
