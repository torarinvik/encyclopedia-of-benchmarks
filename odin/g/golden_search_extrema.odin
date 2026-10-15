package golden_search_extrema
import "core:c"
EPSILON :: 1.0e-7
MIN_WIDTH :: 2.0e-7
objective :: proc(id:int,x:f64)->f64 {if id==0{return (x-2.0)*(x-2.0)};return math.cos(x)}
@(export)
golden_search_extrema :: proc "c" (objective_id,left,right:f64)->f64 {
 if objective_id!=0.0&&objective_id!=1.0 do return -1.0
 if objective_id==0.0&&(!(left>=0.0&&left<=4.0)||!(right>=0.0&&right<=4.0)) do return -1.0
 if objective_id==1.0&&(!(left>=2.0&&left<=4.0)||!(right>=2.0&&right<=4.0)) do return -1.0
 a:=left;b:=right;if a>b {t:=a;a=b;b=t}
 extremum:=2.0;if objective_id==1.0 {extremum=3.14159265358979323846}
 if b-a<MIN_WIDTH||!(a<extremum&&extremum<b) do return -1.0
 id:=int(objective_id);mean:=f64(math.inf);previous_mean:=f64(math.inf);phi:=1.61803400516510009765625
 for i:=0;i<128&&math.abs(b-a)>EPSILON;i+=1 {previous_mean=mean;ratio:=(b-a)/phi;c:=b-ratio;d:=a+ratio;if objective(id,c)<objective(id,d){b=d}else{a=c};mean=(a+b)/2.0}
 return previous_mean
}
