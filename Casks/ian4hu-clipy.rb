cask "ian4hu-clipy" do
  version "1.2.10"
  sha256 "197eac38b68bfd6ef8040833900d8328c9dd9e4de39e81e5e5a7de5d0a32d15e"

  url "https://github.com/ian4hu/Clipy/releases/download/#{version}/Clipy.app.zip"
  name "Clipy"
  desc "Clipboard extension app"
  homepage "https://github.com/ian4hu/Clipy"

  livecheck do
    url "https://github.com/ian4hu/Clipy/releases/latest/download/appcast.xml"
    strategy :sparkle
  end

  auto_updates true
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
