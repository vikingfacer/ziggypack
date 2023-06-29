const std = @import("std");

const msg = struct {
    float16: f16 = 0.0,
    float32: f32 = 0.02,
    float64: f64 = 0.0444,
    float128: f128 = 0.2119214,
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
    fn fun() void {}
};

pub fn main() u8 {
    const testmsg1 = testmsg{};
    pack(testmsg, testmsg1);

    return 0;
}

fn pack(comptime packstruct: type, data: anytype) void {
    _ = data;
    // this part is for struct
    switch (@typeInfo(packstruct)) {
        .Bool => {
            std.debug.print("is a Bool {}\n", .{data});
        },
        .Float => {
            std.debug.print("is a float {}\n", .{data});
        },
        .Int => |i| {
            const signedness = std.builtin.Signedness;
            if (i.signedness == signedness.signed) {
                std.debug.print("is a signed Int {}\n", .{data});
            } else {
                std.debug.print("is a unsigned Int {}\n", .{data});
            }
        },
        .Array => |a| {
            std.debug.print("is an []\n", .{});
            for (data) |item| {
                pack(a.child, item);
            }
        },
        .Struct => |s| {
            std.debug.print("is struct\n", .{});
            inline for (s.fields) |f| {
                pack(f.field_type, @field(data, f.name));
            }
        },
        .Optional => {
            std.debug.print("is Optional \n", .{});
        },
        .Null => {
            std.debug.print("is Null\n", .{});
        },
        else => {},
    }
}
