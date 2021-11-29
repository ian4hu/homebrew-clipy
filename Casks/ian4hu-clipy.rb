cask "ian4hu-clipy" do
  version "1.2.11"
  sha256 "757dfefdab200100f20487cc41ebd7e59de456ae50ff13481dafc0a72f657466"

  url "https://github.com/ian4hu/Clipy/releases/download/#{version}/Clipy.app.zip"
  name "Clipy"
  desc "Clipboard extension app for macOS."
  homepage "https://github.com/ian4hu/Clipy"

  livecheck do 
    url "https://github.com/ian4hu/Clipy/releases/latest/download/appcast.xml"
    strategy :sparkle
  end

  depends_on macos: ">= :yosemite"

  app "Clipy.app"

  uninstall quit: "com.clipy-app.Clipy"

  zap trash: [
    "~/Library/Application Support/Clipy",
    "~/Library/Application Support/com.clipy-app.Clipy",
    "~/Library/Caches/com.clipy-app.Clipy",
    "~/Library/Caches/com.crashlytics.data/com.clipy-app.Clipy",
    "~/Library/Caches/io.fabric.sdk.mac.data/com.clipy-app.Clipy",
    "~/Library/Cookies/com.clipy-app.Clipy.binarycookies",
    "~/Library/Preferences/com.clipy-app.Clipy.plist",
  ]
end
