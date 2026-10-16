const INVALID:i64=-9223372036854775808;
export fn needleman_wunsch(v:[*]const i64,n:usize)i64{
 if(n<5 or n>261)return INVALID;const a=v[0];const b=v[1];const ms=v[2];const mm=v[3];const gap=v[4];
 if(a<0 or a>128 or b<0 or b>128 or ms<0 or ms>10 or mm< -10 or mm>0 or gap< -10 or gap>0 or n!=5+@as(usize,@intCast(a+b)))return INVALID;
 for(0..@as(usize,@intCast(a+b)))|k|{if(v[k+5]<65 or v[k+5]>90)return INVALID;}
 var dp:[129]i64=@splat(0);for(0..@as(usize,@intCast(b))+1)|j|{dp[j]=@as(i64,@intCast(j))*gap;}
 for(1..@as(usize,@intCast(a))+1)|i|{var diagonal=dp[0];dp[0]=@as(i64,@intCast(i))*gap;for(1..@as(usize,@intCast(b))+1)|j|{const old=dp[j];const score=if(v[5+i-1]==v[5+@as(usize,@intCast(a))+j-1])ms else mm;const x=diagonal+score;const y=old+gap;const z=dp[j-1]+gap;dp[j]=@max(x,@max(y,z));diagonal=old;}}return dp[@intCast(b)];
}
