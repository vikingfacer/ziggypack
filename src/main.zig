const std = @import("std");
const pack = @import("ziggy-pack.zig");

const msg = struct {
    float32: f32 = 0.02,
    float64: f64 = 0.0444,
};

const testmsg = struct {
    a: [5]u32 = [_]u32{ 1, 2, 3, 4, 5 },
    t: bool = true,
    f: bool = false,
    nil: @Type(.Null) = null,
    int8: i8 = -1,
    int16: i16 = -2,
    int32: i32 = -3,
    int64: i64 = -4,
    unt8: u8 = 1,
    unt16: u16 = 2,
    unt32: u32 = 3,
    unt64: u64 = 4,
    m: msg = msg{},
};

pub fn main() !u8 {
    const testmsg1 = testmsg{};
    const ps = pack.packSize(testmsg1);
    var a = [_]u8{0} ** ps;
    std.debug.print("a len: {}\n", .{a.len});

    var i: usize = 0;
    pack.pack(a[0..a.len], &i, testmsg1);

    for (a) |item| {
        std.debug.print("{x}", .{item});
    }
    return 0;
}
