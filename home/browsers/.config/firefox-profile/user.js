// sign-in / account nags — nuclear option, kills Sync entirely
user_pref("identity.fxaccounts.enabled", false);

// the messaging system that drives most in-product popups
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
user_pref("browser.discovery.enabled", false);
user_pref("messaging-system.rsexperimentloader.enabled", false);

// "here's what's new!" after every update
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.messaging-system.whatsNewPanel.enabled", false);

// new tab clutter
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.default.sites", "");

// misc
user_pref("browser.preferences.moreFromMozilla", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);

// userChrome.css (toolbars at the bottom) -- without this the file is ignored
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// extensions.txt: firefox-profile-setup drops .xpis into <profile>/extensions.
// The default (15) leaves those disabled behind an "add extension?" prompt;
// 14 clears the profile-scope bit so they come up enabled.
user_pref("extensions.autoDisableScopes", 14);
