use clap::Parser;

#[derive(Parser, Debug)]
#[command(
    name = "red_level",
    about = "System-level software dimming and blue/green blocking filters to prevent PWM flicker.",
    version = "1.0.0"
)]
struct Args {
    /// Brightness level in percentage (1 to 100)
    #[arg(short, long, default_value_t = 100)]
    brightness: u8,

    /// Block 100% of Blue and Green light (leaving only Red active)
    #[arg(short, long)]
    red_only: bool,

    /// Reset screen color and brightness back to standard system defaults
    #[arg(long)]
    reset: bool,
}

fn main() {
    let args = Args::parse();

    let clamped_brightness = args.brightness.clamp(1, 100);
    let scale = if args.reset { 1.0 } else { clamped_brightness as f64 / 100.0 };
    let red_only = if args.reset { false } else { args.red_only };

    if args.reset {
        println!("Resetting screen filter and restoring original gamma curves...");
    } else {
        println!(
            "Applying Filter -> Software Brightness: {}% | Red-Only mode: {}",
            clamped_brightness,
            if red_only { "ON" } else { "OFF" }
        );
    }

    #[cfg(target_os = "windows")]
    {
        windows_impl::apply_filter(scale, red_only);
    }

    #[cfg(target_os = "macos")]
    {
        macos_impl::apply_filter(scale, red_only);
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        eprintln!("Error: This application is currently only optimized for macOS and Windows platforms.");
    }
}

// ==========================================
// WINDOWS GDI ENGINE
// ==========================================
#[cfg(target_os = "windows")]
mod windows_impl {
    use std::ffi::c_void;
    use windows::Win32::Graphics::Gdi::GetDC;
    use windows::Win32::UI::ColorSystem::SetDeviceGammaRamp;

    pub fn apply_filter(brightness_scale: f64, red_only: bool) {
        let hdc = unsafe { GetDC(None) };
        if hdc.is_invalid() {
            eprintln!("Error: Failed to acquire display device context (HDC).");
            return;
        }

        let mut ramp = [0u16; 768];

        for i in 0..256 {
            let val = (i as f64 / 255.0) * 65535.0;

            // Base scaling for Red channel
            ramp[i] = (val * brightness_scale).round() as u16;

            if red_only {
                ramp[i + 256] = 0; // Black Green
                ramp[i + 512] = 0; // Black Blue
            } else {
                ramp[i + 256] = (val * brightness_scale).round() as u16;
                ramp[i + 512] = (val * brightness_scale).round() as u16;
            }
        }

        let result = unsafe { SetDeviceGammaRamp(hdc, ramp.as_ptr() as *const c_void) };
        if result.as_bool() {
            println!("System display filter applied successfully.");
        } else {
            eprintln!("Error: SetDeviceGammaRamp failed. Native HDR or administrative limits may apply.");
        }
    }
}

// ==========================================
// macOS COREGRAPHICS FFI ENGINE
// ==========================================
#[cfg(target_os = "macos")]
mod macos_impl {
    type CGDirectDisplayID = u32;
    type CGError = i32;

    #[link(name = "CoreGraphics", kind = "framework")]
    extern "C" {
        fn CGMainDisplayID() -> CGDirectDisplayID;
        fn CGSetDisplayTransferByTable(
            display: CGDirectDisplayID,
            table_size: u32,
            red_table: *const f32,
            green_table: *const f32,
            blue_table: *const f32,
        ) -> CGError;
    }

    pub fn apply_filter(brightness_scale: f64, red_only: bool) {
        let display_id = unsafe { CGMainDisplayID() };
        const TABLE_SIZE: usize = 256;
        
        let mut red_table = [0.0f32; TABLE_SIZE];
        let mut green_table = [0.0f32; TABLE_SIZE];
        let mut blue_table = [0.0f32; TABLE_SIZE];

        for i in 0..TABLE_SIZE {
            let val = (i as f32 / (TABLE_SIZE - 1) as f32) * brightness_scale as f32;

            red_table[i] = val;
            if red_only {
                green_table[i] = 0.0;
                blue_table[i] = 0.0;
            } else {
                green_table[i] = val;
                blue_table[i] = val;
            }
        }

        let result = unsafe {
            CGSetDisplayTransferByTable(
                display_id,
                TABLE_SIZE as u32,
                red_table.as_ptr(),
                green_table.as_ptr(),
                blue_table.as_ptr(),
            )
        };

        if result == 0 {
            println!("System display filter applied successfully.");
        } else {
            eprintln!("Error: CGSetDisplayTransferByTable failed with code {}.", result);
        }
    }
}
