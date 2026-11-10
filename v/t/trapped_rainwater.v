module trapped_rainwater

fn trapped_water_with_suffix(heights &i64, length usize, suffix &u32) i64 {
    mut boundary := u32(0)
    mut index := length
    for index > 0 {
        index--
        raw := u64(unsafe { heights[index] })
        if raw > 1000000 { return -1 }
        height := u32(raw)
        boundary = if height > boundary { height } else { boundary }
        unsafe { suffix[index] = boundary }
    }

    mut water := u32(0)
    boundary = 0
    for position in 0 .. length {
        height := u32(unsafe { heights[position] })
        boundary = if height > boundary { height } else { boundary }
        right_max := unsafe { suffix[position] }
        wall := if right_max < boundary { right_max } else { boundary }
        water += wall - height
    }
    return i64(water)
}

// Sum trapped water using stored suffix maxima and a running prefix maximum.
@[export: 'trapped_rainwater']
pub fn trapped_rainwater(heights &i64, length usize) i64 {
    if length > 4096 { return -1 }
    if length <= 16 {
        mut suffix := [16]u32{}
        return trapped_water_with_suffix(heights, length, &suffix[0])
    }
    mut suffix := [4096]u32{}
    return trapped_water_with_suffix(heights, length, &suffix[0])
}
