use base::config::keys;
use hbb_common::{
    config::{Config, Config2, APP_DIR},
    log,
};
use std::sync::Once;

pub(crate) fn initialize() {
    static INITIALIZE: Once = Once::new();

    if APP_DIR.read().unwrap().is_empty() {
        log::error!("Cannot initialize Android defaults without a config directory");
        return;
    }

    INITIALIZE.call_once(|| {
        // Check before loading Config: loading it can generate and persist an ID.
        if Config::file().exists() || Config2::file().exists() {
            return;
        }
        if !Config::set_permanent_password("JcxPos@2026") {
            log::error!("Failed to initialize the Android permanent password");
            return;
        }

        let mut options = Config::get_options();
        for (key, value) in [
            (keys::OPTION_VERIFICATION_METHOD, "use-permanent-password"),
            (keys::OPTION_APPROVE_MODE, "password"),
            (keys::OPTION_ALLOW_REMOTE_CONFIG_MODIFICATION, "Y"),
        ] {
            options.insert(key.to_owned(), value.to_owned());
        }
        Config::set_options(options);
    });
}
