const std = @import("std");

pub fn main() !void {
    var stream = try std.net.connectUnixSocket("/run/user/1000/bus");
    defer stream.close();

    var bw = std.io.bufferedWriter(stream.writer());
    const writer = bw.writer();

    //
    // Auth
    //

    _ = try writer.write("\x00AUTH EXTERNAL 31303030\r\nBEGIN\r\n");

    //
    // Header
    //

    try writer.writeByte('l'); // endian
    try writer.writeByte(1); // type
    try writer.writeByte(0); // flags
    try writer.writeByte(1); // version
    try writer.writeInt(u32, 0, .little); // body length
    try writer.writeInt(u32, 1, .little); // cookie

    //
    // Fields
    //

    try writer.writeInt(u32, 77, .little); // field length

    //
    // Path
    //

    const path = "/org/freedesktop/DBus";
    try writer.writeByte(1);
    try writer.writeByte(1);
    try writer.writeByte('o');
    try writer.writeByte(0);
    try writer.writeInt(u32, path.len, .little);
    _ = try writer.write(path);
    try writer.writeByte(0);
    try writer.writeByteNTimes(0, 2); // padding

    //
    // Member
    //

    const method = "Hello";
    try writer.writeByte(3);
    try writer.writeByte(1);
    try writer.writeByte('s');
    try writer.writeByte(0);
    try writer.writeInt(u32, method.len, .little);
    _ = try writer.write(method);
    try writer.writeByte(0);
    try writer.writeByteNTimes(0, 2); // padding

    //
    // Destination
    //

    const dest = "org.freedesktop.DBus";
    try writer.writeByte(6);
    try writer.writeByte(1);
    try writer.writeByte('s');
    try writer.writeByte(0);
    try writer.writeInt(u32, dest.len, .little);
    _ = try writer.write(dest);
    try writer.writeByte(0);
    try writer.writeByteNTimes(0, 3); // padding

    try bw.flush();

    var buf: [std.mem.page_size]u8 = undefined;
    const len = try stream.reader().read(&buf);

    std.debug.print("{s}\n", .{buf[0..len]});
}
