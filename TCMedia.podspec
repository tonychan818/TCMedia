Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "TCMedia"
s.summary = "TCMedia."
s.requires_arc = true

# 2
s.version = "0.1.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "[Your Name Goes Here]" => "[Your_Email@Your_Email_Domain.com]" }

# For example,
# s.author = { "Tony Chan" => "siucchan9@gmail.com" }


# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/tonychan818/TCMedia.git"

# For example,
# s.homepage = "https://github.com/tonychan818/TCMedia.git"


# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "[Your RWPickFlavor Git URL Goes Here]", :tag => "#{s.version}"}

# For example,
# s.source = { :git => "https://github.com/JRG-Developer/RWPickFlavor.git", :tag => "#{s.version}"}


# 7
s.framework = "UIKit"
s.dependency 'SCRecorder'
s.dependency 'SVProgressHUD'

# 8
s.source_files = "TCMedia/**/*.{swift}"

# 9
s.resources = "TCMedia/**/*.{png,jpeg,jpg,storyboard,xib}"
end