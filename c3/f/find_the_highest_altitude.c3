module find_the_highest_altitude;

fn long find_the_highest_altitude(long* input, usz length) @export("find_the_highest_altitude") {
    if(input==null||length<1||input[0]<0||input[0]>1024||length!=(usz)input[0]+1)return -1;
    usz n=(usz)input[0];long altitude=0,maximum=0;
    for(usz i=0;i<n;i++){long gain=input[i+1];if(gain < -2147483648l||gain>2147483647l)return -1;altitude+=gain;if(altitude>maximum)maximum=altitude;}
    return maximum;
}
