fn hashValue(h0:u64,value:i64)u64{var h=h0;const bits=@as(u64,@bitCast(value));for(0..8)|i|{h=(h^((bits>>@as(u6,@intCast(8*i)))&255))*%0x100000001b3;}return h;}
export fn gcounter(a:[*c]const i64,n:usize)i64{
 if(a==null or n<2 or n>386)return -1;const nodes_v=a[0];const count=a[1];if(nodes_v<1 or nodes_v>8 or count<0 or count>128 or n!=2+3*@as(usize,@intCast(count)))return -1;
 const nodes:usize=@intCast(nodes_v);var s:[64]i64=@splat(0);var h:u64=0xcbf29ce484222325;
 for(0..@as(usize,@intCast(count)))|i|{const op=a[2+3*i];const aa=a[3+3*i];const bb=a[4+3*i];if(aa<0 or aa>=nodes_v)return -1;const ai:usize=@intCast(aa);
 if(op==0){if(bb!=0 or s[ai*8+ai]>=1000000)return -1;s[ai*8+ai]+=1;}
 else if(op==1){if(bb!=0)return -1;var total:i64=0;for(0..nodes)|j|{total+=s[ai*8+j];}h=hashValue(h,total);}
 else if(op==2){if(bb<0 or bb>=nodes_v)return -1;const bi:usize=@intCast(bb);var yes=true;for(0..nodes)|j|{if(s[ai*8+j]>s[bi*8+j])yes=false;}h=hashValue(h,if(yes)1 else 0);}
 else if(op==3){if(bb<0 or bb>=nodes_v)return -1;const bi:usize=@intCast(bb);for(0..nodes)|j|{if(s[bi*8+j]>s[ai*8+j])s[ai*8+j]=s[bi*8+j];}}
 else{return -1;}}
 for(0..nodes)|i|{for(0..nodes)|j|{h=hashValue(h,s[i*8+j]);}}return @bitCast(h);
}
