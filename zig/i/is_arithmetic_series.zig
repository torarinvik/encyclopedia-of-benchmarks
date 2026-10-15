const MAX_LENGTH:usize=64; const BOUND:i64=1_000_000;
export fn is_arithmetic_series(values:[*]const i64,length:usize)i64 {
 if(length==0 or length>MAX_LENGTH)return -1;
 for(0..length)|i|{if(values[i]<-BOUND or values[i]>BOUND)return -1;}
 if(length==1)return 1; const d=values[1]-values[0];
 for(1..length-1)|i|{if(values[i+1]-values[i]!=d)return 0;} return 1;
}
