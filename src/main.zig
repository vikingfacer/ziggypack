const std = @import("std");

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
    const ps = packSize(testmsg1);
    var a = [_]u8{0} ** ps;
    std.debug.print("a len: {}\n", .{a.len});

    var i: usize = 0;
    pack(a[0..a.len], &i, testmsg1);

    for (a) |item| {
        std.debug.print("{x}", .{item});
    }
    return 0;
}
const hbm = 0x001F;
const obm = 0x00FF;
const tbm = 0x0FFF;
const fbm = 0xFFFF;

// to make this comptime I need to figure out the size first for the buffer aka Array
fn packSize(data: anytype) comptime_int {

    // obm: one byte mask
    // tbm: two byte mask
    // fbm: four byte mask

    var pack_size: usize = 0;
    // this part is for struct

    switch (@typeInfo(@TypeOf(data))) {
        .Bool => {
            pack_size += 1;
        },
        .Float => |f| {
            if (f.bits == 32 or f.bits == 64) {
                pack_size += 1 + f.bits / 8;
            } else {
                @compileError("MsgPack does not support Float 16 or Float 128");
            }
        },
        .Int => |i| {
            pack_size += 1 + (i.bits / 8);
        },
        .Array => |a| {
            if (@TypeOf(a.child) == u8) {
                // parse as str
                if (a.sentinel) {
                    if (a.len <= 31) {
                        pack_size += 1;
                    } else if (a.len > 31 and a.len <= obm) {
                        pack_size += 2;
                    } else if (a.len > obm and a.len <= tbm) {
                        pack_size += 3;
                    } else if (a.len > tbm and a.len <= fbm) {
                        pack_size += 4;
                    } else {
                        @compileError("[_:0]u8 is too large for MsgPack");
                    }
                } else {
                    // parse as bin
                    if (a.len <= obm) {
                        pack_size += 2;
                    } else if (a.len > obm and a.len <= tbm) {
                        pack_size += 3;
                    } else if (a.len > tbm and a.len <= fbm) {
                        pack_size += 5;
                    } else {
                        @compileError("[_]u8 is too large for MsgPack");
                    }
                }
                pack_size += a.len;
            } else {
                // parse as array
                if (a.len <= 15) {
                    pack_size += 1;
                } else if (a.len > 15 and a.len <= obm) {
                    pack_size += 3;
                } else if (a.len > tbm and a.len <= fbm) {
                    pack_size += 5;
                } else {
                    @compileError("[]Type is too large for MsgPack");
                }
                pack_size += a.len * packSize(a.child);
            }
        },
        .Struct => |s| {
            // parse as array
            if (s.fields.len <= 15) {
                pack_size += 1;
            } else if (s.fields.len > 15 and s.fields.len <= obm) {
                pack_size += 3;
            } else if (s.fields.len > tbm and s.fields.len <= fbm) {
                pack_size += 5;
            } else {
                @compileError("[]Type is too large for MsgPack");
            }
            inline for (s.fields) |f| {
                pack_size += packSize(f.name);
                pack_size += packSize(@field(data, f.name));
            }
        },
        .Null => {
            pack_size += 1;
        },
        .Pointer => |p| {
            // string liters
            const slice = std.builtin.TypeInfo.Pointer.Size.Slice;
            if (p.child == u8 and p.size == slice and p.is_const) {
                if (data.len <= 31) {
                    pack_size += 1;
                } else if (data.len > 31 and data.len <= obm) {
                    pack_size += 2;
                } else if (data.len > obm and data.len <= tbm) {
                    pack_size += 3;
                } else if (data.len > tbm and data.len <= fbm) {
                    pack_size += 4;
                } else {
                    @compileError("[]const u8 is too large for MsgPack");
                }
                pack_size += data.len;
            } else {
                @compileError("Cannot Parse Pointer Type");
            }
        },
        .Optional => {},
        .Type => {},
        else => |u| {
            @compileLog(u);
            @compileError("Type not supported");
        },
    }
    return pack_size;
}

fn pack(data: anytype) void {
    // this part is for struct
    switch (@typeInfo(@TypeOf(data))) {
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
            if (a.sentinel) |sent| {
                std.debug.print("is an []\n", .{sent});
            } else {
                for (data) |item| {
                    pack(item);
                }
            }
        },
        .Struct => |s| {
            std.debug.print("is struct\n", .{});
            inline for (s.fields) |f| {
                pack(@field(data, f.name));
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
