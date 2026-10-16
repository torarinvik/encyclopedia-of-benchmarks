module simple_neural_network;
extern fn double exp(double value);
const double INVALID=-1.0e300;
fn double simple_neural_network(long* values,usz length) @export("simple_neural_network") {if(values==null||length!=3)return INVALID;long expected=values[0],initial=values[1],count=values[2];if(expected<0||expected>100||initial<1||initial>199||initial%2!=1||count<1||count>65536)return INVALID;double target=(double)expected/100.0,weight=(double)initial,layer=0.0;for(long i=0;i<count;i++){layer=1.0/(1.0+exp(-0.02*weight));double error=target-layer;double delta=error*layer*(1.0-layer);weight+=0.02*delta;}return layer*100.0;}
