fn put32(out: [*]u8, x: u32) void { var b=x;for(0..4)|i|{out[i]=@truncate(b);b>>=8;} }
fn putf(out: [*]u8, x: f64) void { var b: u64=@bitCast(x);for(0..8)|i|{out[4+i]=@truncate(b);b>>=8;} }
export fn evaluate_expression(v: [*c]const i64,n: usize,out: [*c]u8,cap: usize) i64 {
    if(v==null or n<3 or n>131)return -1;const count=v[0];if(count<1 or count>64 or n!=1+2*@as(usize,@intCast(count)))return -1;
    var st=[_]f64{0}**64;var depth:usize=0;var valid=true;
    for(0..@intCast(count))|i|{const op=v[1+2*i];const x=v[2+2*i];if(op==0){if(x < -1000000000 or x>1000000000)return -1;st[depth]=@as(f64,@floatFromInt(x))/1000.0;depth+=1;}
    else if(op>=1 and op<=4){if(x!=0)return -1;if(depth<2){valid=false;break;}depth-=1;const r=st[depth];depth-=1;const l=st[depth];if(op==1)st[depth]=l+r else if(op==2)st[depth]=l-r else if(op==3)st[depth]=l*r else if(r==0.0){valid=false;break;}else st[depth]=l/r;depth+=1;}
    else{valid=false;break;}}
    valid=valid and depth==1;const need:usize=if(valid)12 else 4;if(out==null or cap<need)return -2;put32(out,if(valid)1 else 0);if(valid)putf(out,st[0]);return @intCast(need);
}
