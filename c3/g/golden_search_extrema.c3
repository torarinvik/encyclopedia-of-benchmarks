module golden_search_extrema;
extern fn double cos(double x);
extern fn double fabs(double x);
const double EPSILON=1.0e-7, MIN_WIDTH=2.0e-7, PI=3.14159265358979323846;
fn double objective(int id,double x){return id==0?(x-2.0)*(x-2.0):cos(x);}
fn double golden_search_extrema(double objective_id,double left,double right) @export("golden_search_extrema") {
 if(objective_id!=0.0&&objective_id!=1.0)return -1.0;
 if(objective_id==0.0&&(!(left>=0.0&&left<=4.0)||!(right>=0.0&&right<=4.0)))return -1.0;
 if(objective_id==1.0&&(!(left>=2.0&&left<=4.0)||!(right>=2.0&&right<=4.0)))return -1.0;
 double a=left,b=right;if(a>b){double t=a;a=b;b=t;}double e=objective_id==0.0?2.0:PI;
 if(b-a<MIN_WIDTH||!(a<e&&e<b))return -1.0;
 int id=(int)objective_id;double mean=1.0/0.0,previous_mean=1.0/0.0,phi=1.61803400516510009765625;
 for(int i=0;i<128&&fabs(b-a)>EPSILON;i++){previous_mean=mean;double ratio=(b-a)/phi,c=b-ratio,d=a+ratio;if(objective(id,c)<objective(id,d))b=d;else a=c;mean=(a+b)/2.0;}
 return previous_mean;
}
