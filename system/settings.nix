{
  config,
  pkgs,
  lib,
  ...
}: {
  # System settings scaffolding - templates for configuration without applying changes
  # Uncomment and modify sections as needed for your setup

  # This file provides examples of system settings that can be applied
  # All settings are commented out by default to avoid unintended changes

  system.defaults = {
    # macOS Dock settings
    # dock = {
    #   autohide = true;
    #   autohide-delay = 0.0;
    #   autohide-time-modifier = 0.0;
    #   orientation = "bottom";
    #   show-recents = false;
    #   showhidden = true;
    #   static-only = false;
    #   tilesize = 48;
    # };

    # macOS Finder settings
    # finder = {
    #   AppleShowAllExtensions = true;
    #   AppleShowAllFiles = true;
    #   CreateDesktop = false;
    #   FXDefaultSearchScope = "SCcf"; # Search current folder
    #   FXEnableExtensionChangeWarning = false;
    #   FXPreferredViewStyle = "Nlsv"; # List view
    #   QuitMenuItem = true;
    #   ShowPathbar = true;
    #   ShowStatusBar = true;
    # };

    # Global macOS settings
    # NSGlobalDomain = {
    #   AppleInterfaceStyle = "Dark";
    #   AppleInterfaceStyleSwitchesAutomatically = false;
    #   AppleKeyboardUIMode = 3; # Full keyboard access
    #   ApplePressAndHoldEnabled = false;
    #   AppleShowAllExtensions = true;
    #   AppleShowScrollBars = "Always";
    #   InitialKeyRepeat = 14;
    #   KeyRepeat = 1;
    #   NSAutomaticCapitalizationEnabled = false;
    #   NSAutomaticDashSubstitutionEnabled = false;
    #   NSAutomaticPeriodSubstitutionEnabled = false;
    #   NSAutomaticQuoteSubstitutionEnabled = false;
    #   NSAutomaticSpellingCorrectionEnabled = false;
    #   NSDocumentSaveNewDocumentsToCloud = false;
    #   NSNavPanelExpandedStateForSaveMode = true;
    #   NSNavPanelExpandedStateForSaveMode2 = true;
    #   PMPrintingExpandedStateForPrint = true;
    #   PMPrintingExpandedStateForPrint2 = true;
    # };

    # Login window settings
    # loginwindow = {
    #   GuestEnabled = false;
    #   SHOWFULLNAME = false;
    # };

    # Screen capture settings
    # screencapture = {
    #   location = "~/Pictures/Screenshots";
    #   type = "png";
    # };

    # Trackpad settings
    # trackpad = {
    #   Clicking = true;
    #   TrackpadThreeFingerDrag = true;
    # };

    # Universal Access settings
    # universalaccess = {
    #   reduceMotion = true;
    #   reduceTransparency = true;
    # };
  };

  # Keyboard settings
  # keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToEscape = true;
  # };

  # Additional system configuration examples
  # security = {
  #   pam.enableSudoTouchIdAuth = true;
  # };

  # Time zone and locale settings
  # time.timeZone = "America/New_York";
  # i18n = {
  #   defaultLocale = "en_US.UTF-8";
  #   extraLocaleSettings = {
  #     LC_ADDRESS = "en_US.UTF-8";
  #     LC_IDENTIFICATION = "en_US.UTF-8";
  #     LC_MEASUREMENT = "en_US.UTF-8";
  #     LC_MONETARY = "en_US.UTF-8";
  #     LC_NAME = "en_US.UTF-8";
  #     LC_NUMERIC = "en_US.UTF-8";
  #     LC_PAPER = "en_US.UTF-8";
  #     LC_TELEPHONE = "en_US.UTF-8";
  #     LC_TIME = "en_US.UTF-8";
  #   };
  # };
}
