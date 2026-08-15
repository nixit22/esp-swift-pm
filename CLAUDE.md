# SwiftPM

Swift wrapper for ESP-IDF power management (`esp_pm`) — CPU frequency scaling range and automatic light sleep. Swift module name: **`PM`**.

Depends on: `SwiftPlatform`, `SwiftSupport`, `esp_pm`

## Files

| File | Role |
|---|---|
| `src/PM.swift` | `@_exported import ESP_PM` re-exports the raw C API; also defines `PowerManagement`, a plain struct mirroring `esp_pm_config_t` |
| `src/pm.c` / `src/pm.h` | Thin C wrapper — only `#include <esp_pm.h>` |
| `module.modulemap` | Clang module `ESP_PM` — umbrella over `src/pm.h` |

## Public API

```swift
import PM

// Enable automatic light sleep, preserving whatever CONFIG_PM_ENABLE's auto-init
// already set for max/min CPU frequency — only flips the one field auto-init
// doesn't set.
try PowerManagement.enableLightSleep()

// Or explicit read/modify/apply:
var cfg = try PowerManagement.current()   // reads the currently active config
cfg.maxFreqMhz = 80
cfg.lightSleepEnable = true
try cfg.apply()                           // esp_pm_configure
```

`PowerManagement` is a plain (`Copyable`) struct — `esp_pm_config_t` is a value, not a
handle-owning resource, so there's no `~Copyable`/`deinit` lifecycle here unlike
`NVS`/`AdcUnit`.

## Non-obvious patterns

**`light_sleep_enable` requires two more sdkconfig symbols, not just this API.**
`CONFIG_PM_ENABLE=y` and `CONFIG_FREERTOS_USE_TICKLESS_IDLE=y` (the latter `depends on
PM_ENABLE`, `default n`) must both be set — `apply()`/`enableLightSleep()` alone won't
engage light sleep if either is missing. `CONFIG_PM_ENABLE`'s own auto-init sets
`max_freq_mhz`/`min_freq_mhz` from sdkconfig at boot but never sets
`light_sleep_enable` — that field only ever gets set by an explicit
`esp_pm_configure()` call at runtime, which is what this component exists to make
ergonomic.

**No manual pointer bridging needed, on either side of the wrapper.** `esp_pm_configure`/
`esp_pm_get_configuration` take `const void*`/`void*` in C. Swift's inout-to-pointer
sugar (`&cfg`) bridges directly to those parameter types without an explicit
`withUnsafeMutablePointer`/`UnsafeMutableRawPointer` cast — confirmed empirically. The
component's own `current()`/`apply()` use plain `&cfg`; callers never see a pointer at
all, matching the requirement that drove building this component instead of calling
`esp_pm_configure` raw from application code.

**`@_exported import ESP_PM`** — re-exports the C module so callers get `esp_pm_config_t`,
`esp_pm_configure`, `esp_pm_get_configuration`, etc. with a single `import PM`, though the
typical caller only needs `PowerManagement` itself.

**No runtime logic in C glue** — `pm.c` is empty except for `#include "pm.h"`. It exists
solely so the component has a C compilation unit (required by ESP-IDF component
registration), same as `esp-swift-nvs`/`esp-swift-ledc`.
