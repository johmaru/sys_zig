const std = @import("std");
const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").system.system_services;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").graphics.gdi;
    usingnamespace @import("zigwin32").system.library_loader;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").system.system_information;
    usingnamespace @import("zigwin32").system.process_status;
};
const windowlongptr = @import("zigwin32").windowlongptr;
const L = win32.L;
const HWND = win32.HWND;

pub const GetWindow = struct {
    var hInstance: win32.HINSTANCE = undefined;
    var hwndMain: ?win32.HWND = null;
    var isInitialized: bool = false;

    const DisplayText = struct {
        x: i32 = 0,
        y: i32 = 0,
        text: [*:0]const u8 = "test",
        len: i32,
    };
    var texts: std.ArrayList(DisplayText) = undefined;

    fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
        if (std.fmt.allocPrintZ(std.heap.page_allocator, fmt, args)) |msg| {
            _ = win32.MessageBoxA(null, msg, "Error", .{});
        } else |e| switch (e) {
            error.OutOfMemory => _ = win32.MessageBoxA(null, "OutOfMemory", "FatalError", .{}),
        }
        std.process.exit(1);
    }

    pub fn init() !void {
        hInstance = win32.GetModuleHandleW(null) orelse {
            return error.FailedToGetModuleHandle;
        };

        isInitialized = true;

        texts = std.ArrayList(DisplayText).init(std.heap.page_allocator);
    }

    fn showWindowThred() !void {
        if (!isInitialized) {
            return error.InstanceNotInitialized;
        }

        const empty: [*:0]const u16 = L("");
        _ = GetWindow.wWinMain(hInstance, null, empty, 0);
    }

    pub fn ShowWindow() !std.Thread {
        if (!isInitialized) {
            return error.InstanceNotInitialized;
        }
        return try std.Thread.spawn(.{}, showWindowThred, .{});
    }

    pub fn ShutdownWindow() !void {
        if (GetWindow.hwndMain) |hwnd| {
            if (win32.IsWindow(hwnd) != 0) {
                _ = win32.PostMessageW(hwnd, win32.WM_CLOSE, 0, 0);

                var timeout: u32 = 0;
                while (win32.IsWindow(hwnd) != 0 and timeout < 100) {
                    std.time.sleep(10 * std.time.ns_per_ms);
                    timeout += 1;
                }

                if (win32.IsWindow(hwnd) != 0) {
                    return error.WindowNotClosed;
                }

                GetWindow.hwndMain = null;
            }
        }

        if (win32.UnregisterClassW(L("WindowClass"), GetWindow.hInstance) == 0) {
            GetWindow.fatal("UnregisterClassA failed : {s}\n", .{win32.GetLastError().fmt()});
        }
    }

    pub fn addText(x: i32, y: i32, text: [*:0]const u8) !void {
        try texts.append(.{
            .x = x,
            .y = y,
            .text = text,
            .len = @intCast(std.mem.len(text)),
        });
    }

    export fn wWinMain(
        instance: win32.HINSTANCE,
        _: ?win32.HINSTANCE,
        pCmdLine: [*:0]const u16,
        nCmdShow: u32,
    ) callconv(WINAPI) c_int {
        hInstance = instance;
        _ = pCmdLine;
        _ = nCmdShow;

        const CLASS_NAME = L("WindowClass");
        var wc: win32.WNDCLASSW = undefined;

        wc.style = .{ .HREDRAW = 1, .VREDRAW = 1 };
        wc.lpfnWndProc = GetWindow.windowProc;
        wc.cbClsExtra = 0;
        wc.cbWndExtra = 0;
        wc.hInstance = hInstance;
        wc.hIcon = null;
        wc.hCursor = null;
        wc.hbrBackground = null;
        wc.lpszMenuName = null;
        wc.lpszClassName = CLASS_NAME;

        if (win32.RegisterClassW(&wc) == 0) {
            GetWindow.fatal("RegisterClassA failed : {s}\n", .{win32.GetLastError().fmt()});
        }
        hwndMain = win32.CreateWindowExW(.{}, CLASS_NAME, L("Test"), win32.WS_OVERLAPPEDWINDOW, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, 400, 200, null, null, hInstance, null) orelse {
            GetWindow.fatal("CreateWindowEx failed : {s}\n", .{win32.GetLastError().fmt()});
        };

        _ = win32.ShowWindow(hwndMain, .{ .SHOWNORMAL = 1 });
        _ = win32.UpdateWindow(hwndMain);

        var msg: win32.MSG = undefined;
        while (win32.GetMessageW(&msg, null, 0, 0) != 0) {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageW(&msg);
        }

        return @intCast(msg.wParam);
    }

    fn windowProc(hwnd: HWND, uMsg: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(WINAPI) win32.LRESULT {
        switch (uMsg) {
            win32.WM_DESTROY => {
                win32.PostQuitMessage(0);
                return 0;
            },
            win32.WM_PAINT => {
                var ps: win32.PAINTSTRUCT = undefined;
                const hdc = win32.BeginPaint(hwnd, &ps);
                _ = win32.FillRect(hdc, &ps.rcPaint, @ptrFromInt(@intFromEnum(win32.COLOR_WINDOW) + 1));
                for (texts.items) |text| {
                    _ = win32.TextOutA(hdc, text.x, text.y, text.text, text.len);
                }
                _ = win32.EndPaint(hwnd, &ps);
                return 0;
            },
            else => {},
        }
        return win32.DefWindowProcW(hwnd, uMsg, wParam, lParam);
    }
};

pub const GetSystemInfo = struct {
    var sysInfo: win32.SYSTEM_INFO = undefined;
    pub const c_name_format = win32.COMPUTER_NAME_FORMAT;
    pub const Processor_relationship = win32.LOGICAL_PROCESSOR_RELATIONSHIP;

    pub const Memsize = struct {
        gb: ?bool = false,
        mb: ?bool = false,
        kb: ?bool = false,

        pub fn toU64(self: *const Memsize, value: u64) u64 {
            if (self.gb.?) {
                return value / (1024 * 1024);
            } else if (self.mb.?) {
                return value / 1024;
            } else if (self.kb.?) {
                return value * 1024;
            } else {
                return value;
            }
        }
    };

    pub fn init() !void {
        win32.GetSystemInfo(&sysInfo);
    }

    pub fn GetComputerName(format: win32.COMPUTER_NAME_FORMAT) ![]u8 {
        var size: u32 = 0;

        _ = win32.GetComputerNameExW(format, null, &size);
        if (win32.GetLastError() != .ERROR_MORE_DATA) {
            return error.FailedToGetComputerName;
        }
        const allocator = std.heap.page_allocator;
        const buffer = try allocator.alloc(u16, size);
        defer allocator.free(buffer);

        if (win32.GetComputerNameExW(format, @ptrCast(buffer.ptr), &size) == 0) {
            return error.FailedToGetComputerName;
        }

        const utf8Size = size * 3;

        const result = try allocator.alloc(u8, utf8Size);
        errdefer allocator.free(result);

        const actual_size = try std.unicode.utf16leToUtf8(result, buffer[0..size]);

        return try allocator.realloc(result, actual_size);
    }

    pub fn GetDisplayIntegratedDisplaySize() f64 {
        var displaySize: f64 = 0.0;
        _ = win32.GetIntegratedDisplaySize(&displaySize);
        return displaySize;
    }

    pub fn GetLocalTime() win32.SYSTEMTIME {
        var localTime: win32.SYSTEMTIME = undefined;
        win32.GetLocalTime(&localTime);
        return localTime;
    }

    pub fn GetLogicalProcessorInfo(relation: win32.LOGICAL_PROCESSOR_RELATIONSHIP) !win32.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX {
        var size: u32 = 0;

        _ = win32.GetLogicalProcessorInformationEx(relation, null, &size);
        if (win32.GetLastError() != .ERROR_INSUFFICIENT_BUFFER) {
            return error.FailedToGetLogicalProcessorInfo;
        }

        const allocator = std.heap.page_allocator;
        const buffer = try allocator.create(win32.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX);
        defer allocator.destroy(buffer);

        if (win32.GetLogicalProcessorInformationEx(relation, buffer, &size) == 0) {
            return error.FailedToGetLogicalProcessorInfo;
        }

        return buffer.*;
    }

    pub fn GetNativeSystemInfo() win32.SYSTEM_INFO {
        var n_sysInfo: win32.SYSTEM_INFO = undefined;
        win32.GetNativeSystemInfo(&n_sysInfo);
        return n_sysInfo;
    }

    pub fn GetMemorySpace(size: ?Memsize) u64 {
        var value: u64 = undefined;
        const ptr: *u64 = &value;
        _ = win32.GetPhysicallyInstalledSystemMemory(@ptrCast(ptr));
        if (size) |mem_size| {
            return mem_size.toU64(value);
        }

        return value;
    }

    pub fn GetProcessorCycleTime(group: u16) !u64 {
        const sys_info = GetNativeSystemInfo();
        const max_groups = (sys_info.dwNumberOfProcessors + 63) / 64;
        if (group >= max_groups) {
            return error.InvalidProcessorGroup;
        }

        var return_length: u32 = 0;
        _ = win32.GetProcessorSystemCycleTime(group, null, &return_length);
        if (win32.GetLastError() != .ERROR_INSUFFICIENT_BUFFER) {
            return error.FailedToGetProcessorCycleTime;
        }

        const allocator = std.heap.page_allocator;
        const buffer = try allocator.alignedAlloc(u8, 8, return_length);
        defer allocator.free(buffer);

        if (win32.GetProcessorSystemCycleTime(group, @ptrCast(@alignCast(buffer.ptr)), &return_length) == 0) {
            const err = win32.GetLastError();
            std.debug.print("GetProcessorSystemCycleTime failed : {}\n", .{err});
            return error.FailedToGetProcessorCycleTime;
        }

        const cycleTime = @as(*const u64, @ptrCast(buffer.ptr)).*;

        return cycleTime;
    }

    pub fn GetSystemDirectory() ![]const u8 {
        const size = win32.GetSystemDirectoryW(null, 0);
        if (size == 0) {
            return error.FailedToGetSystemDirectory;
        }

        const allocator = std.heap.page_allocator;
        const buffer = try allocator.alloc(u16, size);

        if (win32.GetSystemDirectoryW(@ptrCast(buffer.ptr), size) == 0) {
            allocator.free(buffer);
            return error.FailedToGetSystemDirectory;
        }

        const utf8Size = size * 3;
        const result = try allocator.alloc(u8, utf8Size);
        errdefer allocator.free(result);

        const actual_size = try std.unicode.utf16leToUtf8(result, buffer[0..size]);

        return try allocator.realloc(result, actual_size);
    }

    pub fn GetWindowsDirectory() ![]const u8 {
        const size = win32.GetWindowsDirectoryW(null, 0);
        if (size == 0) {
            return error.FailedToGetWindowsDirectory;
        }

        const allocator = std.heap.page_allocator;
        const buffer = try allocator.alloc(u16, size);

        if (win32.GetWindowsDirectoryW(@ptrCast(buffer.ptr), size) == 0) {
            allocator.free(buffer);
            return error.FailedToGetWindowsDirectory;
        }

        const utf8Size = size * 3;
        const result = try allocator.alloc(u8, utf8Size);
        errdefer allocator.free(result);

        const actual_size = try std.unicode.utf16leToUtf8(result, buffer[0..size]);

        return try allocator.realloc(result, actual_size);
    }

    pub fn GetSystemTime() win32.SYSTEMTIME {
        var systemTime: win32.SYSTEMTIME = undefined;
        win32.GetSystemTime(&systemTime);
        return systemTime;
    }
};
