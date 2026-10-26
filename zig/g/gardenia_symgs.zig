// Clean-room bounded GARDENIA SymGS profile.
const std=@import("std");
export fn gardenia_symgs(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    const N:usize=8;const M:usize=64;const IMAX:usize=173;
    if(input_opt==null or length<3 or length>IMAX)return -1;const input=input_opt.?;
    for(0..length)|q|if(!std.math.isFinite(input[q]))return -1;
    const nd=input[0];const md=input[1];const cd=input[2];if(@trunc(nd)!=nd or @trunc(md)!=md or @trunc(cd)!=cd or nd<1 or nd>8 or md<1 or md>64 or cd<1 or cd>nd)return -1;
    const n:usize=@intFromFloat(nd);const m:usize=@intFromFloat(md);const colors:usize=@intFromFloat(cd);if(length!=5+4*n+colors+2*m)return -1;
    const oa:usize=3;const fa=oa+n;const ra=fa+colors+1;const ca=ra+n+1;const va=ca+m;const xa=va+m;const ba=xa+n;
    var order:[N]usize=@splat(0);var offsets:[N+1]usize=@splat(0);var rows:[N+1]usize=@splat(0);var cols:[M]usize=@splat(0);var group:[N]usize=@splat(0);var seen:[N]bool=@splat(false);
    var mat:[M]f64=@splat(0);var x:[N]f64=@splat(0);var rhs:[N]f64=@splat(0);var staged:[N]f64=@splat(0);
    for(0..n)|i|{const z=input[oa+i];if(@trunc(z)!=z or z<0 or z>=nd)return -1;const v:usize=@intFromFloat(z);if(seen[v])return -1;order[i]=v;seen[v]=true;}
    for(0..colors+1)|k|{const z=input[fa+k];if(@trunc(z)!=z or z<0 or z>nd)return -1;offsets[k]=@intFromFloat(z);}
    if(offsets[0]!=0 or offsets[colors]!=n)return -1;for(0..colors)|k|{if(offsets[k]>=offsets[k+1])return -1;for(offsets[k]..offsets[k+1])|p|group[order[p]]=k;}
    for(0..n+1)|i|{const z=input[ra+i];if(@trunc(z)!=z or z<0 or z>md)return -1;rows[i]=@intFromFloat(z);if(i>0 and rows[i]<rows[i-1])return -1;}if(rows[0]!=0 or rows[n]!=m)return -1;
    for(0..n)|u|{var diag:usize=0;var d:f64=0;var offsum:f64=0;var prev:usize=0;for(rows[u]..rows[u+1])|e|{const z=input[ca+e];if(@trunc(z)!=z or z<0 or z>=nd)return -1;cols[e]=@intFromFloat(z);if(e>rows[u] and cols[e]<=prev)return -1;prev=cols[e];mat[e]=input[va+e];if(mat[e]<-4 or mat[e]>4)return -1;if(cols[e]==u){diag+=1;d=mat[e];}else{if(group[u]==group[cols[e]])return -1;offsum+=@abs(mat[e]);}}
        if(diag!=1 or d<=offsum)return -1;for(rows[u]..rows[u+1])|e|{const v=cols[e];var found=false;for(rows[v]..rows[v+1])|f|{if(cols[f]==u){if(mat[f]!=mat[e])return -1;found=true;break;}}if(!found)return -1;}}
    for(0..n)|i|{x[i]=input[xa+i];rhs[i]=input[ba+i];if(x[i]<-4 or x[i]>4 or rhs[i]<-4 or rhs[i]>4)return -1;}
    if(output_opt==null or capacity<n)return -2;
    for(0..2)|pass|{for(0..colors)|step|{const k=if(pass==0)step else colors-1-step;for(offsets[k]..offsets[k+1])|p|{const u=order[p];var sum:f64=0;var diag:f64=0;for(rows[u]..rows[u+1])|e|{const v=cols[e];if(v==u){diag=mat[e];}else{sum+=x[v]*mat[e];}}if(diag!=0){x[u]=(rhs[u]-sum)/diag;}}}}
    for(0..n)|i|staged[i]=x[i];const output=output_opt.?;for(0..n)|i|output[i]=staged[i];return @intCast(n);
}
