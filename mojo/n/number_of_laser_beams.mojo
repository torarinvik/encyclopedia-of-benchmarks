from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("number_of_laser_beams")
def number_of_laser_beams(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if input == None or length < 2 or length > 4098:
        return -1
    var values = input.value()
    var rows = values[unsafe_offset=0]
    var columns = values[unsafe_offset=1]
    if rows < 1 or rows > 64 or columns < 1 or columns > 64:
        return -1
    if length != c_size_t(rows * columns + 2):
        return -1

    var invalid_bits: UInt64 = 0
    var previous_devices: UInt64 = 0
    var beams: UInt64 = 0
    var row_start = 2
    while row_start < Int(length):
        var devices: UInt64 = 0
        for column in range(Int(columns)):
            var cell = UInt64(values[unsafe_offset=row_start + column])
            invalid_bits |= cell ^ 48
            devices += cell & 1
        beams += devices * previous_devices
        previous_devices = devices if devices != 0 else previous_devices
        row_start += Int(columns)
    if invalid_bits > 1:
        return -1
    return Int64(beams)
