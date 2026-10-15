const std=@import("std");
const EPSILON:f64=1.0e-7;
const MIN_WIDTH:f64=2.0e-7;
fn objective(id:i32,x:f64)f64{return if(id==0)(x-2.0)*(x-2.0) else @cos(x);}
/// Return the previous midpoint from the source golden-section iteration.
export fn golden_search_extrema(objective_id:f64,left:f64,right:f64)f64{
 if(objective_id!=0.0 and objective_id!=1.0)return -1.0;
 if(objective_id==0.0 and (!(left>=0.0 and left<=4.0) or !(right>=0.0 and right<=4.0)))return -1.0;
 if(objective_id==1.0 and (!(left>=2.0 and left<=4.0) or !(right>=2.0 and right<=4.0)))return -1.0;
 var a=left;var b=right;if(a>b){const t=a;a=b;b=t;}const id:i32=@intFromFloat(objective_id);const e=if(id==0)2.0 else std.math.pi;
 if(b-a<MIN_WIDTH or !(a<e and e<b))return -1.0;
 var mean=std.math.INF_F64;var previous_mean=std.math.INF_F64;const phi=1.61803400516510009765625;
 for(0..128)|_|{if(@abs(b-a)<=EPSILON)break;previous_mean=mean;const ratio=(b-a)/phi;const c=b-ratio;const d=a+ratio;if(objective(id,c)<objective(id,d)){b=d;}else{a=c;}mean=(a+b)/2.0;}
 return previous_mean;
}
