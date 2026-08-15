// Copyright (c) 2026 Nicolas Christe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@_exported import ESP_PM
import Platform

private let log = Logger(tag: "PM")

/// Wraps `esp_pm_config_t` — CPU frequency scaling range and automatic light sleep.
///
/// `light_sleep_enable` also requires `CONFIG_PM_ENABLE` and
/// `CONFIG_FREERTOS_USE_TICKLESS_IDLE` set in sdkconfig — `CONFIG_PM_ENABLE`'s own
/// auto-init sets `maxFreqMhz`/`minFreqMhz` from sdkconfig but never sets
/// `lightSleepEnable`, so `apply()`/`enableLightSleep()` is required at runtime to
/// actually engage automatic light sleep.
public struct PowerManagement {
    public var maxFreqMhz: Int32
    public var minFreqMhz: Int32
    public var lightSleepEnable: Bool

    public init(maxFreqMhz: Int32, minFreqMhz: Int32, lightSleepEnable: Bool) {
        self.maxFreqMhz = maxFreqMhz
        self.minFreqMhz = minFreqMhz
        self.lightSleepEnable = lightSleepEnable
    }

    /// Reads the currently active PM configuration.
    ///
    /// - Throws: `Error` on failure.
    public static func current() throws(Error) -> PowerManagement {
        var cfg = esp_pm_config_t()
        try esp_pm_get_configuration(&cfg)
            .throwEspError {
                log.w("esp_pm_get_configuration failed: \($0.name)")
            }
        return PowerManagement(maxFreqMhz: cfg.max_freq_mhz, minFreqMhz: cfg.min_freq_mhz,
                                lightSleepEnable: cfg.light_sleep_enable)
    }

    /// Applies this configuration.
    ///
    /// - Throws: `Error` on failure.
    public func apply() throws(Error) {
        var cfg = esp_pm_config_t(max_freq_mhz: maxFreqMhz, min_freq_mhz: minFreqMhz,
                                   light_sleep_enable: lightSleepEnable)
        try esp_pm_configure(&cfg)
            .throwEspError {
                log.w("esp_pm_configure failed: \($0.name)")
            }
    }

    /// Convenience: reads the current configuration, enables automatic light sleep, reapplies.
    /// Preserves whatever `maxFreqMhz`/`minFreqMhz` `CONFIG_PM_ENABLE`'s auto-init already set —
    /// only changes the one field auto-init doesn't set.
    ///
    /// - Throws: `Error` on failure.
    public static func enableLightSleep() throws(Error) {
        var cfg = try current()
        cfg.lightSleepEnable = true
        try cfg.apply()
    }
}
