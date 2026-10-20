// Bounded beta=2 lune graph adapted from ParGeo; see benchmarks/b/beta_skeleton/LICENSE.txt.
pub export fn beta_skeleton(values:?[*]const i64,length:usize,output:?[*]u8,output_capacity:usize)i64{
    const input=values orelse return -1;if(length<3 or length>65)return -1;const n0=input[0];if(n0<1 or n0>32 or length!=1+2*@as(usize,@intCast(n0)))return -1;const n:usize=@intCast(n0);
    var x:[32]i64=@splat(0);var y:[32]i64=@splat(0);
    for(0..n)|i|{x[i]=input[1+2*i];y[i]=input[2+2*i];if(x[i]<-1000 or x[i]>1000 or y[i]<-1000 or y[i]>1000)return -1;for(0..i)|j|{if(x[i]==x[j] and y[i]==y[j])return -1;}}
    var edges:[992]u8=@splat(0);var count:usize=0;
    for(0..n)|i|{for(i+1..n)|j|{const dx=x[i]-x[j];const dy=y[i]-y[j];const d2=dx*dx+dy*dy;var blocked=false;
        for(0..n)|k|{if(k==i or k==j)continue;const aix=x[k]-x[i];const aiy=y[k]-y[i];const ajx=x[k]-x[j];const ajy=y[k]-y[j];if(aix*aix+aiy*aiy<d2 and ajx*ajx+ajy*ajy<d2){blocked=true;break;}}
        if(!blocked){edges[count]=@intCast(i);edges[count+1]=@intCast(j);count+=2;}
    }}
    const out=output orelse return -2;if(output_capacity<count)return -2;for(0..count)|i|{out[i]=edges[i];}return @intCast(count);
}
