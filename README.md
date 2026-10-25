# SwiftPM

Swift power-management wrapper for ESP-IDF's `esp_pm` — CPU frequency scaling range and automatic light sleep. Exposes `PowerManagement`, a plain struct mirroring `esp_pm_config_t` with `current()`/`apply()`/`enableLightSleep()`. Swift module name: **`PM`**.

Depends on: `SwiftPlatform`, `SwiftSupport`, `esp_pm`.

## Adding it to a project

This is a [SwiftPM](https://www.swift.org/package-manager/) package, built for ESP-IDF by
`swift_package()` from [esp-swift-support](https://github.com/nixit22/esp-swift-support). In your
app's `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nixit22/esp-swift-pm.git", branch: "SPM"),
],
targets: [
    .target(name: "App", dependencies: [.product(name: "PM", package: "esp-swift-pm")]),
]
```

See esp-swift-support's README for the project setup (top-level `CMakeLists.txt`, `main`
component, Swift toolchain).

## Usage

```swift
import PM

// Enable automatic light sleep, keeping whatever CONFIG_PM_ENABLE already set for CPU frequency.
try PowerManagement.enableLightSleep()

// Or read/modify/apply explicitly:
var cfg = try PowerManagement.current()
cfg.lightSleepEnable = true
try cfg.apply()
```

Requires `CONFIG_PM_ENABLE=y` and `CONFIG_FREERTOS_USE_TICKLESS_IDLE=y` in sdkconfig — light sleep won't engage from `lightSleepEnable = true` alone. See [`CLAUDE.md`](CLAUDE.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
