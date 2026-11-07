
// ---- X96 OS defaults (S905W, 2 GB RAM) ----
// Ask YouTube for H.264 instead of VP9/AV1: far cheaper to decode on the Cortex-A53.
pref("media.av1.enabled", false);
pref("media.mediasource.webm.enabled", false);
pref("media.mediasource.vp9.enabled", false);
// Fewer content processes, unload tabs when memory is low.
pref("dom.ipc.processCount", 2);
pref("dom.ipc.processCount.webIsolated", 1);
pref("browser.tabs.unloadOnLowMemory", true);
pref("browser.low_commit_space_threshold_mb", 400);
pref("browser.sessionstore.interval", 60000);
pref("browser.cache.disk.capacity", 131072);
pref("browser.preferences.defaultPerformanceSettings.enabled", false);
// Lima only offers OpenGL ES 2: use Firefox's software WebRender path explicitly.
pref("gfx.webrender.software", true);
// Less background work.
pref("datareporting.healthreport.uploadEnabled", false);
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("toolkit.telemetry.enabled", false);
pref("app.normandy.enabled", false);
pref("app.shield.optoutstudies.enabled", false);
pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
pref("browser.newtabpage.activity-stream.showSponsored", false);
pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
pref("extensions.pocket.enabled", false);
pref("widget.gtk.overlay-scrollbars.enabled", true);
