module perimeter;

fn long perimeter(long* values, usz length) @export("perimeter") {
    if(values==null||length!=2)return -1;
    long sides=values[0], side_length=values[1];
    if(sides<3||sides>256||side_length<1||side_length>255)return -1;
    return sides*side_length;
}
