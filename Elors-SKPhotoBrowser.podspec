Pod::Spec.new do |s|
  s.name         = "Elors-SKPhotoBrowser"
  s.version      = "3.1.5"
  s.summary      = "PhotoBrowser forked by SKPhotoBrowser"
  s.homepage     = "https://github.com/Elors/SKPhotoBrowser"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Elors" => "ElorsAt@gmail.com" }
  s.source       = { :git => "https://github.com/Elors/SKPhotoBrowser.git", :tag => s.version }
  s.platform     = :ios, "8.0"
  s.source_files = "SKPhotoBrowser/**/*.{h,swift}"
  s.resources    = "SKPhotoBrowser/SKPhotoBrowser.bundle"
  s.requires_arc = true
  s.frameworks   = "UIKit"
end
