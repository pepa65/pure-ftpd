// lspdb.zig - Print all "key:value" pairs in a given PureDB .pdb file
// Build for local use: zig build-exe lspdb.zig
// Build for wider use: zig build-exe -lc -target x86_64-linux-gnu lspdb.zig

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len != 2) {
        try std.io.getStdErr().writer().print("usage: {s} <file.pdb>\n", .{std.os.argv[0]});
        std.os.exit(254);
    }
    const path = args[1];

    var fd = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer fd.close();
    const pdb = try fd.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(pdb);
    if (pdb.len < 4 or !std.mem.startsWith(u8, pdb, "PDB2")) {
        try std.io.getStdErr().writer().print("File is not a PDB file\n", .{});
        std.os.exit(1);
    }

    var offset = std.mem.readIntBig(u32, pdb[1028..][0..4]);
    var writer = std.io.getStdOut().writer();
    while (offset < pdb.len) {
        var len = std.mem.readIntBig(u32, pdb[offset..][0..4]);
        try writer.print("{s}:", .{pdb[offset + 4 ..][0..len]});
        offset += len + 4;
        len = std.mem.readIntBig(u32, pdb[offset..][0..4]);
        try writer.print("{s}\n", .{pdb[offset + 4 ..][0..len]});
        offset += len + 4;
    }
}
