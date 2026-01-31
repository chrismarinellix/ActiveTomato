// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{
    Manager,
    LogicalSize,
    LogicalPosition,
    tray::TrayIconBuilder,
    menu::{Menu, MenuItem},
    WebviewWindow,
};
use std::sync::atomic::{AtomicU8, Ordering};

// 0 = full, 1 = widget, 2 = mini
static VIEW_MODE: AtomicU8 = AtomicU8::new(0);

fn apply_view_mode(window: &WebviewWindow, mode: u8) {
    VIEW_MODE.store(mode, Ordering::SeqCst);

    match mode {
        2 => {
            // Mini mode - super compact, just timer and progress
            let _ = window.set_size(LogicalSize::new(220.0, 90.0));
            let _ = window.set_decorations(false);
            let _ = window.set_always_on_top(true);
            let _ = window.set_skip_taskbar(true);

            // Position top-right
            if let Ok(monitor) = window.current_monitor() {
                if let Some(monitor) = monitor {
                    let size = monitor.size();
                    let scale = monitor.scale_factor();
                    let x = (size.width as f64 / scale) - 240.0;
                    let y = 40.0;
                    let _ = window.set_position(LogicalPosition::new(x, y));
                }
            }

            let _ = window.eval(r#"
                document.body.classList.remove('widget-mode');
                document.body.classList.add('mini-mode');

                // Create window controls (traffic lights + drag area)
                if (!document.getElementById('window-controls')) {
                    const controls = document.createElement('div');
                    controls.id = 'window-controls';
                    controls.style.cssText = `
                        position: fixed;
                        top: 0;
                        left: 0;
                        right: 0;
                        height: 28px;
                        display: flex;
                        align-items: center;
                        padding: 0 10px;
                        z-index: 9999;
                        cursor: grab;
                    `;
                    controls.innerHTML = `
                        <div id="traffic-lights" style="display: flex; gap: 6px;">
                            <div id="btn-close" style="width: 12px; height: 12px; border-radius: 50%; background: #ff5f57; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 8px; color: transparent;" onmouseenter="this.style.color='rgba(0,0,0,0.5)'" onmouseleave="this.style.color='transparent'">✕</div>
                            <div id="btn-mini" style="width: 12px; height: 12px; border-radius: 50%; background: #febc2e; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 8px; color: transparent;" onmouseenter="this.style.color='rgba(0,0,0,0.5)'" onmouseleave="this.style.color='transparent'">−</div>
                            <div id="btn-expand" style="width: 12px; height: 12px; border-radius: 50%; background: #28c840; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 7px; color: transparent;" onmouseenter="this.style.color='rgba(0,0,0,0.5)'" onmouseleave="this.style.color='transparent'">↗</div>
                        </div>
                    `;
                    controls.onmousedown = (e) => {
                        if (!e.target.id.startsWith('btn-')) {
                            e.preventDefault();
                            window.__TAURI__.window.getCurrentWindow().startDragging();
                        }
                    };
                    document.body.appendChild(controls);

                    document.getElementById('btn-close').onclick = () => window.__TAURI__.window.getCurrentWindow().hide();
                    document.getElementById('btn-mini').onclick = () => window.__TAURI__.core.invoke('set_view_mode', { mode: 2 });
                    document.getElementById('btn-expand').onclick = () => window.__TAURI__.core.invoke('set_view_mode', { mode: 0 });
                }
                document.getElementById('window-controls').style.display = 'flex';
                document.getElementById('btn-mini').style.background = '#febc2e';

                if (!document.getElementById('mini-style')) {
                    const style = document.createElement('style');
                    style.id = 'mini-style';
                    style.textContent = `
                        body.mini-mode {
                            background: transparent !important;
                            overflow: hidden !important;
                        }
                        body.mini-mode .container {
                            padding: 0 !important;
                            background: transparent !important;
                        }
                        body.mini-mode #webgl-bg { display: none !important; }
                        body.mini-mode .eink-screen {
                            height: 100vh !important;
                            max-width: 100% !important;
                            border-radius: 16px !important;
                            background: rgba(245, 245, 240, 0.95) !important;
                            backdrop-filter: blur(20px) !important;
                            -webkit-backdrop-filter: blur(20px) !important;
                            box-shadow: 0 8px 32px rgba(0,0,0,0.3), 0 0 0 1px rgba(0,0,0,0.1) !important;
                            padding: 20px 16px 12px !important;
                            display: flex !important;
                            align-items: center !important;
                            justify-content: center !important;
                        }
                        body.mini-mode .eink-screen::before { display: none !important; }
                        body.mini-mode .screen-content {
                            display: flex !important;
                            flex-direction: column !important;
                            align-items: center !important;
                            justify-content: center !important;
                            overflow: visible !important;
                            width: 100% !important;
                        }
                        body.mini-mode .header,
                        body.mini-mode .activity-section,
                        body.mini-mode .toggle-panels,
                        body.mini-mode .series-selector,
                        body.mini-mode .mode-tabs,
                        body.mini-mode .controls,
                        body.mini-mode .timer-label,
                        body.mini-mode .interval-indicator,
                        body.mini-mode .main-content > *:not(.timer-display):not(.timer-progress) {
                            display: none !important;
                        }
                        body.mini-mode .main-content {
                            padding: 0 !important;
                            display: flex !important;
                            flex-direction: column !important;
                            align-items: center !important;
                            gap: 8px !important;
                        }
                        body.mini-mode .timer-display {
                            margin: 0 !important;
                            display: flex !important;
                        }
                        body.mini-mode .timer-digits {
                            font-size: 2rem !important;
                            font-weight: 600 !important;
                            letter-spacing: 2px !important;
                            color: #1a1a1a !important;
                        }
                        body.mini-mode .timer-progress {
                            width: 100% !important;
                            max-width: 180px !important;
                            height: 4px !important;
                            margin: 0 !important;
                            border-radius: 2px !important;
                            background: rgba(0,0,0,0.1) !important;
                        }
                        body.mini-mode .timer-progress .progress-fill {
                            height: 100% !important;
                            border-radius: 2px !important;
                            background: #1a1a1a !important;
                        }
                    `;
                    document.head.appendChild(style);
                }
                const widgetStyle = document.getElementById('widget-style');
                if (widgetStyle) widgetStyle.remove();
            "#);
        }
        1 => {
            // Widget mode - compact with controls
            let _ = window.set_size(LogicalSize::new(300.0, 400.0));
            let _ = window.set_decorations(false);
            let _ = window.set_always_on_top(true);
            let _ = window.set_skip_taskbar(true);

            if let Ok(monitor) = window.current_monitor() {
                if let Some(monitor) = monitor {
                    let size = monitor.size();
                    let scale = monitor.scale_factor();
                    let x = (size.width as f64 / scale) - 320.0;
                    let y = (size.height as f64 / scale) - 440.0;
                    let _ = window.set_position(LogicalPosition::new(x, y));
                }
            }

            let _ = window.eval(r#"
                document.body.classList.remove('mini-mode');
                document.body.classList.add('widget-mode');

                // Create window controls (traffic lights + drag area)
                if (!document.getElementById('window-controls')) {
                    const controls = document.createElement('div');
                    controls.id = 'window-controls';
                    controls.style.cssText = `
                        position: fixed;
                        top: 0;
                        left: 0;
                        right: 0;
                        height: 28px;
                        display: flex;
                        align-items: center;
                        padding: 0 12px;
                        z-index: 9999;
                        cursor: grab;
                    `;
                    controls.innerHTML = `
                        <div id="traffic-lights" style="display: flex; gap: 6px;">
                            <div id="btn-close" style="width: 12px; height: 12px; border-radius: 50%; background: #ff5f57; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 8px; color: transparent;" onmouseenter="this.style.color='rgba(0,0,0,0.5)'" onmouseleave="this.style.color='transparent'">✕</div>
                            <div id="btn-mini" style="width: 12px; height: 12px; border-radius: 50%; background: #febc2e; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 8px; color: transparent;" onmouseenter="this.style.color='rgba(0,0,0,0.5)'" onmouseleave="this.style.color='transparent'">−</div>
                            <div id="btn-expand" style="width: 12px; height: 12px; border-radius: 50%; background: #28c840; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 7px; color: transparent;" onmouseenter="this.style.color='rgba(0,0,0,0.5)'" onmouseleave="this.style.color='transparent'">↗</div>
                        </div>
                    `;
                    controls.onmousedown = (e) => {
                        if (!e.target.id.startsWith('btn-')) {
                            e.preventDefault();
                            window.__TAURI__.window.getCurrentWindow().startDragging();
                        }
                    };
                    document.body.appendChild(controls);

                    document.getElementById('btn-close').onclick = () => window.__TAURI__.window.getCurrentWindow().hide();
                    document.getElementById('btn-mini').onclick = () => window.__TAURI__.core.invoke('set_view_mode', { mode: 2 });
                    document.getElementById('btn-expand').onclick = () => window.__TAURI__.core.invoke('set_view_mode', { mode: 0 });
                }
                document.getElementById('window-controls').style.display = 'flex';
                document.getElementById('btn-mini').style.background = '#28c840';
                document.getElementById('btn-expand').style.background = '#febc2e';

                if (!document.getElementById('widget-style')) {
                    const style = document.createElement('style');
                    style.id = 'widget-style';
                    style.textContent = `
                        body.widget-mode {
                            background: transparent !important;
                        }
                        body.widget-mode .container {
                            padding: 0 !important;
                            background: transparent !important;
                        }
                        body.widget-mode #webgl-bg { display: none !important; }
                        body.widget-mode .eink-screen {
                            height: 100vh !important;
                            max-width: 100% !important;
                            border-radius: 20px !important;
                            background: rgba(245, 245, 240, 0.95) !important;
                            backdrop-filter: blur(30px) saturate(180%) !important;
                            -webkit-backdrop-filter: blur(30px) saturate(180%) !important;
                            box-shadow: 0 20px 60px rgba(0,0,0,0.3), 0 0 0 1px rgba(0,0,0,0.1) !important;
                            padding: 30px 20px 20px !important;
                        }
                        body.widget-mode .eink-screen::before { display: none !important; }
                        body.widget-mode .header,
                        body.widget-mode .activity-section,
                        body.widget-mode .toggle-panels,
                        body.widget-mode .series-selector { display: none !important; }
                        body.widget-mode .screen-content { overflow: visible !important; }
                        body.widget-mode .main-content {
                            padding: 10px !important;
                            justify-content: center !important;
                        }
                        body.widget-mode .timer-display { margin: 10px 0 !important; }
                        body.widget-mode .timer-digits { font-size: 3.5rem !important; font-weight: 600 !important; }
                        body.widget-mode .timer-label { font-size: 0.65rem !important; }
                        body.widget-mode .mode-tabs { margin-bottom: 15px !important; }
                        body.widget-mode .mode-tab { padding: 8px 14px !important; font-size: 0.6rem !important; }
                        body.widget-mode .timer-progress { max-width: 220px !important; margin-top: 15px !important; }
                        body.widget-mode .interval-indicator { display: none !important; }
                        body.widget-mode .controls { margin: 15px 0 8px !important; gap: 10px !important; }
                        body.widget-mode .btn {
                            padding: 10px 22px !important;
                            font-size: 0.7rem !important;
                            border-radius: 8px !important;
                        }
                    `;
                    document.head.appendChild(style);
                }
                const miniStyle = document.getElementById('mini-style');
                if (miniStyle) miniStyle.remove();
            "#);
        }
        _ => {
            // Full mode
            let _ = window.set_size(LogicalSize::new(1000.0, 750.0));
            let _ = window.set_decorations(false);
            let _ = window.set_always_on_top(false);
            let _ = window.set_skip_taskbar(false);
            let _ = window.center();

            let _ = window.eval(r#"
                document.body.classList.remove('widget-mode');
                document.body.classList.remove('mini-mode');
                const widgetStyle = document.getElementById('widget-style');
                if (widgetStyle) widgetStyle.remove();
                const miniStyle = document.getElementById('mini-style');
                if (miniStyle) miniStyle.remove();
                const windowControls = document.getElementById('window-controls');
                if (windowControls) windowControls.style.display = 'none';
            "#);
        }
    }
}

#[tauri::command]
fn set_view_mode(window: tauri::WebviewWindow, mode: u8) {
    apply_view_mode(&window, mode);
}

#[tauri::command]
fn toggle_widget_mode(window: tauri::WebviewWindow) {
    let current = VIEW_MODE.load(Ordering::SeqCst);
    let next = if current == 0 { 1 } else { 0 };
    apply_view_mode(&window, next);
}

#[tauri::command]
fn cycle_view_mode(window: tauri::WebviewWindow) {
    let current = VIEW_MODE.load(Ordering::SeqCst);
    let next = (current + 1) % 3;
    apply_view_mode(&window, next);
}

#[tauri::command]
fn set_always_on_top(window: tauri::WebviewWindow, on_top: bool) {
    let _ = window.set_always_on_top(on_top);
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![toggle_widget_mode, set_always_on_top, set_view_mode, cycle_view_mode])
        .setup(|app| {
            // Create tray menu
            let show = MenuItem::with_id(app, "show", "Show Full View", true, None::<&str>)?;
            let widget = MenuItem::with_id(app, "widget", "Widget Mode", true, None::<&str>)?;
            let mini = MenuItem::with_id(app, "mini", "Mini Mode", true, None::<&str>)?;
            let hide = MenuItem::with_id(app, "hide", "Hide", true, None::<&str>)?;
            let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show, &widget, &mini, &hide, &quit])?;

            // Build tray icon
            let app_handle = app.handle().clone();
            TrayIconBuilder::new()
                .icon(app.default_window_icon().unwrap().clone())
                .menu(&menu)
                .show_menu_on_left_click(false)
                .on_menu_event(move |_app, event| {
                    if let Some(window) = app_handle.get_webview_window("main") {
                        match event.id.as_ref() {
                            "show" => {
                                let _ = window.show();
                                let _ = window.set_focus();
                                apply_view_mode(&window, 0);
                            }
                            "widget" => {
                                let _ = window.show();
                                let _ = window.set_focus();
                                apply_view_mode(&window, 1);
                            }
                            "mini" => {
                                let _ = window.show();
                                let _ = window.set_focus();
                                apply_view_mode(&window, 2);
                            }
                            "hide" => {
                                let _ = window.hide();
                            }
                            "quit" => {
                                std::process::exit(0);
                            }
                            _ => {}
                        }
                    }
                })
                .on_tray_icon_event(|tray, event| {
                    if let tauri::tray::TrayIconEvent::Click { button: tauri::tray::MouseButton::Left, .. } = event {
                        let app = tray.app_handle();
                        if let Some(window) = app.get_webview_window("main") {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                })
                .build(app)?;

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
